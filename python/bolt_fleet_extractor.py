#!/usr/bin/env python3
"""
bolt_fleet_extractor.py (Enterprise Raw Ingestion)
===================================================
Extrage datele brute din Bolt Fleet Integration API fara nicio modificare
de structura sau de tipuri de date (Timestamp-urile raman Unix Epoch brute).
Suporta extragere standard si Weekly Backfill (Luni - Duminica).
"""

from __future__ import annotations

from dotenv import load_dotenv
# Cauta automat fisierul .env si incarca variabilele
load_dotenv()

import argparse
import json
import logging
import os
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Iterable

import requests
from azure.storage.blob import BlobServiceClient

try:
    import pandas as pd
except ImportError:
    raise SystemExit("Lipseste pandas. Ruleaza: pip install pandas pyarrow python-dotenv requests azure-storage-blob")

TOKEN_URL = "https://oidc.bolt.eu/token"
BASE_URL = "https://node.bolt.eu/fleet-integration-gateway/fleetIntegration/v1"
SCOPE = "fleet-integration:api"

MAX_LIMIT_DEFAULT = 1000
MAX_LIMIT_VEHICLES = 100
TOKEN_SAFETY_MARGIN_S = 60
DEFAULT_CHUNK_DAYS = 28
DEFAULT_LOOKBACK_DAYS = 7   # Implicit extragem ultimele 7 zile (Enterprise Weekly Incremental)

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-7s | %(message)s", datefmt="%H:%M:%S")
log = logging.getLogger("bolt")


@dataclass
class BoltAuth:
    client_id: str
    client_secret: str
    _token: str | None = field(default=None, init=False, repr=False)
    _expires_at: float = field(default=0.0, init=False, repr=False)

    def _fetch_token(self) -> None:
        log.info("Obtin token OIDC de la %s", TOKEN_URL)
        resp = requests.post(
            TOKEN_URL,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={"client_id": self.client_id, "client_secret": self.client_secret,
                  "grant_type": "client_credentials", "scope": SCOPE},
            timeout=30,
        )
        if resp.status_code != 200:
            raise RuntimeError(f"Autentificare esuata ({resp.status_code}): {resp.text[:300]}")
        data = resp.json()
        self._token = data["access_token"]
        self._expires_at = time.time() + data.get("expires_in", 600) - TOKEN_SAFETY_MARGIN_S

    @property
    def token(self) -> str:
        if self._token is None or time.time() >= self._expires_at:
            self._fetch_token()
        return self._token  # type: ignore[return-value]


class BoltFleetClient:
    def __init__(self, auth: BoltAuth, max_retries: int = 4):
        self.auth = auth
        self.max_retries = max_retries
        self.session = requests.Session()

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        url = f"{BASE_URL}{path}"
        for attempt in range(1, self.max_retries + 1):
            headers = {"Authorization": f"Bearer {self.auth.token}", "Content-Type": "application/json"}
            try:
                resp = self.session.request(method, url, headers=headers, data=json.dumps(body) if body is not None else None, timeout=60)
            except requests.RequestException:
                time.sleep(2 ** attempt)
                continue

            if resp.status_code == 401 and attempt == 1:
                self.auth._token = None
                continue
            if resp.status_code in (429, 500, 502, 503, 504):
                time.sleep(2 ** attempt)
                continue

            payload = resp.json()
            return payload
        raise RuntimeError(f"Cerere esuata: {method} {path}")

    def get_companies(self) -> list[int]:
        data = self._request("GET", "/getCompanies").get("data", {})
        return data.get("company_ids", [])

    def _paginate(self, path: str, base_body: dict, data_key: str, max_limit: int) -> list[dict]:
        results: list[dict] = []
        offset = 0
        while True:
            body = {**base_body, "limit": max_limit, "offset": offset}
            data = self._request("POST", path, body).get("data", {})
            batch = data.get(data_key, []) or []
            results.extend(batch)
            log.info("    %s: +%d (total %d)", data_key, len(batch), len(results))
            if len(batch) < max_limit:
                break
            offset += max_limit
            time.sleep(0.15)
        return results

    def get_orders(self, cid, s, e, filt="created"):
        return self._paginate("/getFleetOrders", {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e, "time_range_filter_type": filt}, "orders", MAX_LIMIT_DEFAULT)

    def get_state_logs(self, cid, s, e):
        return self._paginate("/getFleetStateLogs", {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}, "state_logs", MAX_LIMIT_DEFAULT)

    def get_drivers(self, cid, s, e):
        return self._paginate("/getDrivers", {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}, "drivers", MAX_LIMIT_DEFAULT)

    def get_vehicles(self, cid, s, e):
        return self._paginate("/getVehicles", {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}, "vehicles", MAX_LIMIT_VEHICLES)


def date_chunks(start: datetime, end: datetime, chunk_days: int) -> Iterable[tuple[int, int]]:
    cur = start
    delta = timedelta(days=chunk_days)
    while cur < end:
        nxt = min(cur + delta, end)
        yield int(cur.timestamp()), int(nxt.timestamp())
        cur = nxt


def build_raw_dataframe(records: list[dict], run_ts: str) -> pd.DataFrame:
    """
    Aplatizeaza JSON-ul pastrand campurile brute si adauga metadata de ingestie.
    """
    if not records:
        return pd.DataFrame()

    df = pd.json_normalize(records, sep=".")

    # Convertim doar listele/dict-urile imbricate ramase in string JSON curat
    for col in df.columns:
        if df[col].apply(lambda v: isinstance(v, (list, dict))).any():
            df[col] = df[col].apply(lambda v: json.dumps(v, ensure_ascii=False) if isinstance(v, (list, dict)) else v)

    # Metadate Enterprise pentru trasabilitate in Power BI / Azure Data Lake
    df["ingestion_timestamp"] = run_ts
    return df


def save_df(df: pd.DataFrame, file_prefix: str, out_dir: Path) -> None:
    if df is None or df.empty:
        return
    
    csv_path = out_dir / f"{file_prefix}.csv"
    parquet_path = out_dir / f"{file_prefix}.parquet"

    df.to_csv(csv_path, index=False, encoding="utf-8-sig")
    try:
        df.to_parquet(parquet_path, index=False)
    except Exception:
        pass
    
    log.info("  Salvat %s (%d randuri, %d coloane)", csv_path.name, len(df), df.shape[1])


def save_raw(records: list[dict], name: str, raw_dir: Path) -> None:
    if not records:
        return
    (raw_dir / f"{name}.json").write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")


def load_credentials(fleet_dir: Path) -> tuple[str, str]:
    env_path = fleet_dir / "myKey.env"
    creds: dict[str, str] = {}
    if env_path.exists():
        for line in env_path.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                creds[k.strip()] = v.strip()
    cid = creds.get("BOLT_CLIENT_ID") or os.environ.get("BOLT_CLIENT_ID")
    secret = creds.get("BOLT_CLIENT_SECRET") or os.environ.get("BOLT_CLIENT_SECRET")
    if not cid or not secret:
        raise SystemExit(f"Nu gasesc credentialele in {env_path}")
    return cid, secret


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Bolt Fleet Raw Extractor (Enterprise)")
    p.add_argument("--fleet", default=".", help="Folderul flotei")
    p.add_argument("--start", help="Data start YYYY-MM-DD")
    p.add_argument("--end", help="Data end YYYY-MM-DD")
    p.add_argument("--days-back", type=int, default=DEFAULT_LOOKBACK_DAYS, help="Ultimele N zile (default 7)")
    p.add_argument("--chunk-days", type=int, default=DEFAULT_CHUNK_DAYS)
    p.add_argument("--backfill-weekly", action="store_true", help="Extrage automat saptamana cu saptamana (Luni-Duminica)")
    return p.parse_args()


def extract_for_period(client: BoltFleetClient, company_ids: list[int], start: datetime, end: datetime, chunk_days: int) -> tuple[list, list, dict, dict]:
    orders_raw, logs_raw = [], []
    drivers_by_key, vehicles_by_key = {}, {}

    for cidx in company_ids:
        for s_ts, e_ts in date_chunks(start, end, chunk_days):
            orders_raw += client.get_orders(cidx, s_ts, e_ts)
            logs_raw += client.get_state_logs(cidx, s_ts, e_ts)
            for d in client.get_drivers(cidx, s_ts, e_ts):
                drivers_by_key[d.get("driver_uuid") or d.get("uuid") or id(d)] = d
            for v in client.get_vehicles(cidx, s_ts, e_ts):
                vehicles_by_key[v.get("uuid") or id(v)] = v

    return orders_raw, logs_raw, drivers_by_key, vehicles_by_key


def upload_to_azure_bronze(local_file_path: Path, blob_name: str) -> None:
    """Incarca un fisier local direct in containerul Bronze din Azure Blob Storage."""
    connect_str = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    container_name = "bronze"

    if not connect_str:
        print("⚠️ Variabila AZURE_STORAGE_CONNECTION_STRING nu a fost gasita. Skip upload cloud.")
        return

    if not local_file_path.exists():
        return

    try:
        blob_service_client = BlobServiceClient.from_connection_string(connect_str)
        blob_client = blob_service_client.get_blob_client(container=container_name, blob=blob_name)

        print(f"☁️ Se incarca {blob_name} in Azure Container '{container_name}'...")
        with open(local_file_path, "rb") as data:
            blob_client.upload_blob(data, overwrite=True)
        print(f"✅ Incarcat cu succes in Azure: {blob_name}")
    except Exception as e:
        print(f"❌ Eroare la incarcarea in Azure: {e}")

        
def main() -> None:
    args = parse_args()
    fleet_dir = Path(args.fleet).expanduser().resolve()
    cid_secret = load_credentials(fleet_dir)
    client = BoltFleetClient(BoltAuth(*cid_secret))
    company_ids = client.get_companies()

    # Folderul unificat Bronze Ingestion setat direct in /data din radacina proiectului
    project_root = fleet_dir.parent if fleet_dir.name == "python" else fleet_dir
    out_dir = project_root / "data" / "data_bronze"
    raw_dir = out_dir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    yesterday_end = today_start - timedelta(seconds=1)

    start = (
        datetime.strptime(args.start, "%Y-%m-%d").replace(tzinfo=timezone.utc)
        if args.start
        else today_start - timedelta(days=args.days_back)
    )
    end = (
        datetime.strptime(args.end, "%Y-%m-%d").replace(tzinfo=timezone.utc, hour=23, minute=59, second=59)
        if args.end
        else yesterday_end
    )

    run_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    if args.backfill_weekly:
        log.info("=== START WEEKLY BACKFILL %s -> %s ===", start.date(), end.date())
        current_start = start

        while current_start <= end:
            current_end = min(current_start + timedelta(days=6, hours=23, minutes=59, seconds=59), end)
            year, week_num, _ = current_start.isocalendar()
            week_suffix = f"{year}_W{week_num:02d}"

            log.info("Preluare Saptamana %s (%s -> %s)...", week_suffix, current_start.strftime("%Y-%m-%d %H:%M"), current_end.strftime("%Y-%m-%d %H:%M"))

            orders_raw, logs_raw, drivers_dict, vehicles_dict = extract_for_period(
                client, company_ids, current_start, current_end, args.chunk_days
            )

            # Salvare JSON Brut
            save_raw(orders_raw, f"orders_{week_suffix}", raw_dir)
            save_raw(logs_raw, f"state_logs_{week_suffix}", raw_dir)

            # Salvare CSV / Parquet Local
            save_df(build_raw_dataframe(orders_raw, run_ts), f"orders_{week_suffix}", out_dir)
            save_df(build_raw_dataframe(logs_raw, run_ts), f"state_logs_{week_suffix}", out_dir)
            save_df(build_raw_dataframe(list(drivers_dict.values()), run_ts), f"drivers_{week_suffix}", out_dir)
            save_df(build_raw_dataframe(list(vehicles_dict.values()), run_ts), f"vehicles_{week_suffix}", out_dir)

            # Upload automat in Azure Blob Storage (JSON + CSV)
            upload_to_azure_bronze(raw_dir / f"orders_{week_suffix}.json", f"raw/orders_{week_suffix}.json")
            upload_to_azure_bronze(raw_dir / f"state_logs_{week_suffix}.json", f"raw/state_logs_{week_suffix}.json")
            upload_to_azure_bronze(out_dir / f"orders_{week_suffix}.csv", f"orders_{week_suffix}.csv")
            upload_to_azure_bronze(out_dir / f"state_logs_{week_suffix}.csv", f"state_logs_{week_suffix}.csv")
            upload_to_azure_bronze(out_dir / f"drivers_{week_suffix}.csv", f"drivers_{week_suffix}.csv")
            upload_to_azure_bronze(out_dir / f"vehicles_{week_suffix}.csv", f"vehicles_{week_suffix}.csv")

            current_start += timedelta(days=7)

        log.info("=== BACKFILL SAPTAMANAL FINALIZAT CU SUCCES! ===")

    else:
        log.info("Extragere Standard: %s -> %s", start.date(), end.date())
        orders_raw, logs_raw, drivers_dict, vehicles_dict = extract_for_period(
            client, company_ids, start, end, args.chunk_days
        )

        # Calculam saptamana ISO pentru denumire unificata (ex: 2026_W31)
        year, week_num, _ = start.isocalendar()
        week_suffix = f"{year}_W{week_num:02d}"

        # Salvare JSON Brut
        save_raw(orders_raw, f"orders_{week_suffix}", raw_dir)
        save_raw(logs_raw, f"state_logs_{week_suffix}", raw_dir)
        
        # Salvare CSV / Parquet Local
        save_df(build_raw_dataframe(orders_raw, run_ts), f"orders_{week_suffix}", out_dir)
        save_df(build_raw_dataframe(logs_raw, run_ts), f"state_logs_{week_suffix}", out_dir)
        save_df(build_raw_dataframe(list(drivers_dict.values()), run_ts), f"drivers_{week_suffix}", out_dir)
        save_df(build_raw_dataframe(list(vehicles_dict.values()), run_ts), f"vehicles_{week_suffix}", out_dir)

        # Upload automat in Azure Blob Storage (JSON + CSV)
        upload_to_azure_bronze(raw_dir / f"orders_{week_suffix}.json", f"raw/orders_{week_suffix}.json")
        upload_to_azure_bronze(raw_dir / f"state_logs_{week_suffix}.json", f"raw/state_logs_{week_suffix}.json")
        upload_to_azure_bronze(out_dir / f"orders_{week_suffix}.csv", f"orders_{week_suffix}.csv")
        upload_to_azure_bronze(out_dir / f"state_logs_{week_suffix}.csv", f"state_logs_{week_suffix}.csv")
        upload_to_azure_bronze(out_dir / f"drivers_{week_suffix}.csv", f"drivers_{week_suffix}.csv")
        upload_to_azure_bronze(out_dir / f"vehicles_{week_suffix}.csv", f"vehicles_{week_suffix}.csv")

        log.info("Extragere finalizata cu succes in: %s", out_dir)


if __name__ == "__main__":
    main()