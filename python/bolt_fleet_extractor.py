#!/usr/bin/env python3
"""
bolt_fleet_extractor.py  (v2 - extragere completa, organizare pe flote)
=======================================================================
Extrage ABSOLUT TOT ce ofera Bolt Fleet Integration API si salveaza in
CSV + Parquet + JSON brut. Nu alege manual campuri: aplatizeaza dinamic
orice intoarce API-ul, deci fiecare camp real devine o coloana (chiar si
campuri nedocumentate). Nimic inventat, nimic ratat.

Endpoint-uri:
    getCompanies, getFleetOrders, getFleetStateLogs, getDrivers, getVehicles

------------------------------------------------------------------------
ORGANIZARE PE FLOTE
------------------------------------------------------------------------
Fiecare flota = un folder propriu care contine fisierul `myKey.env`:

    C:\\BoltAnalytics\\
        FlotaMea\\
            myKey.env          <- BOLT_CLIENT_ID / BOLT_CLIENT_SECRET
        AltaFlota\\
            myKey.env

Rulezi indicand folderul flotei (rezultatele se scriu TOT acolo, intr-un
subfolder cu data/ora). Nu mai schimbi nimic in cmd intre flote:

    python bolt_fleet_extractor.py --fleet "C:\\BoltAnalytics\\FlotaMea"
    python bolt_fleet_extractor.py --fleet "C:\\BoltAnalytics\\AltaFlota"

Fara --fleet foloseste folderul curent. Fara date, ia tot istoricul
disponibil (merge ~2 ani in urma; ferestrele goale/prea vechi sunt sarite).

    python bolt_fleet_extractor.py --fleet "...FlotaMea" --start 2026-01-01
    python bolt_fleet_extractor.py --fleet "...FlotaMea" --filter-type price_review

myKey.env (in folderul flotei):
    BOLT_CLIENT_ID=...
    BOLT_CLIENT_SECRET=...
"""

from __future__ import annotations

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

try:
    import pandas as pd
except ImportError:
    raise SystemExit("Lipseste pandas. Ruleaza: pip install pandas pyarrow python-dotenv requests")

try:
    from zoneinfo import ZoneInfo
    LOCAL_TZ = ZoneInfo("Europe/Bucharest")   # gestioneaza corect +02:00 (iarna) / +03:00 (vara)
except Exception:
    LOCAL_TZ = timezone(timedelta(hours=2))    # fallback daca lipseste tzdata

# ---------------------------------------------------------------------------
# Configurare
# ---------------------------------------------------------------------------

TOKEN_URL = "https://oidc.bolt.eu/token"
BASE_URL = "https://node.bolt.eu/fleet-integration-gateway/fleetIntegration/v1"
SCOPE = "fleet-integration:api"

MAX_LIMIT_DEFAULT = 1000
MAX_LIMIT_VEHICLES = 100
TOKEN_SAFETY_MARGIN_S = 60
DEFAULT_CHUNK_DAYS = 28
DEFAULT_LOOKBACK_DAYS = 730   # cand nu se da --start: incearca ~2 ani in urma

BOLT_ERROR_CODES = {
    498805: "INVALID_START_DATE - data de start e inainte de perioada permisa",
    498806: "INVALID_DATE_RANGE - intervalul cerut e prea lung (micsoreaza --chunk-days)",
    498807: "COMPANY_NOT_FOUND - compania nu exista",
    498809: "COMPANY_NOT_ACTIVE / COMPANIES_NOT_ACTIVE - compania nu mai e activa",
    498810: "COMPANY_NOT_ALLOWED - nu ai acces la compania ceruta",
}

# Coloane care contin timestamp-uri unix si trebuie sparte in _date / _time.
TS_SUFFIXES = ("_timestamp", "_ts")
TS_EXACT = {"created", "created_at", "ended_at", "updated_at", "ended", "updated"}

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s | %(levelname)-7s | %(message)s",
                    datefmt="%H:%M:%S")
log = logging.getLogger("bolt")


# ---------------------------------------------------------------------------
# Autentificare
# ---------------------------------------------------------------------------

@dataclass
class BoltAuth:
    client_id: str
    client_secret: str
    _token: str | None = field(default=None, init=False, repr=False)
    _expires_at: float = field(default=0.0, init=False, repr=False)

    def _fetch_token(self) -> None:
        log.info("Obtin token de la %s", TOKEN_URL)
        resp = requests.post(
            TOKEN_URL,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            data={"client_id": self.client_id, "client_secret": self.client_secret,
                  "grant_type": "client_credentials", "scope": SCOPE},
            timeout=30,
        )
        if resp.status_code != 200:
            raise RuntimeError(
                f"Autentificare esuata ({resp.status_code}): {resp.text[:300]}. "
                "Verifica BOLT_CLIENT_ID / BOLT_CLIENT_SECRET din myKey.env."
            )
        data = resp.json()
        self._token = data["access_token"]
        self._expires_at = time.time() + data.get("expires_in", 600) - TOKEN_SAFETY_MARGIN_S

    @property
    def token(self) -> str:
        if self._token is None or time.time() >= self._expires_at:
            self._fetch_token()
        return self._token  # type: ignore[return-value]


# ---------------------------------------------------------------------------
# Client API
# ---------------------------------------------------------------------------

class BoltAPIError(RuntimeError):
    def __init__(self, message: str, code: int | None = None):
        super().__init__(message)
        self.code = code


class BoltFleetClient:
    def __init__(self, auth: BoltAuth, max_retries: int = 4):
        self.auth = auth
        self.max_retries = max_retries
        self.session = requests.Session()

    def _request(self, method: str, path: str, body: dict | None = None) -> dict:
        url = f"{BASE_URL}{path}"
        for attempt in range(1, self.max_retries + 1):
            headers = {"Authorization": f"Bearer {self.auth.token}",
                       "Content-Type": "application/json"}
            try:
                resp = self.session.request(
                    method, url, headers=headers,
                    data=json.dumps(body) if body is not None else None, timeout=60)
            except requests.RequestException as exc:
                wait = 2 ** attempt
                log.warning("Eroare retea (%s). Reincerc in %ss [%d/%d]", exc, wait, attempt, self.max_retries)
                time.sleep(wait)
                continue

            if resp.status_code == 401 and attempt == 1:
                log.info("401 - reinnoiesc token-ul")
                self.auth._token = None
                continue
            if resp.status_code in (429, 500, 502, 503, 504):
                wait = 2 ** attempt
                log.warning("HTTP %s. Backoff %ss [%d/%d]", resp.status_code, wait, attempt, self.max_retries)
                time.sleep(wait)
                continue

            payload = self._safe_json(resp)
            self._raise_on_bolt_error(resp, payload)
            return payload
        raise RuntimeError(f"Cerere esuata dupa {self.max_retries} incercari: {method} {path}")

    @staticmethod
    def _safe_json(resp: requests.Response) -> dict:
        try:
            return resp.json()
        except ValueError:
            raise RuntimeError(f"Raspuns non-JSON ({resp.status_code}): {resp.text[:300]}")

    @staticmethod
    def _raise_on_bolt_error(resp: requests.Response, payload: dict) -> None:
        code = payload.get("code")
        # code==0 inseamna succes; orice cod cunoscut de eroare sau HTTP>=400 = problema
        if resp.status_code >= 400 or (isinstance(code, int) and code in BOLT_ERROR_CODES):
            hint = BOLT_ERROR_CODES.get(code, payload.get("message", resp.text[:300]))
            raise BoltAPIError(f"Eroare API (HTTP {resp.status_code}, code={code}): {hint}", code)

    # ---- endpoint-uri -----------------------------------------------------

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
        body = {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e,
                "time_range_filter_type": filt}
        return self._paginate("/getFleetOrders", body, "orders", MAX_LIMIT_DEFAULT)

    def get_state_logs(self, cid, s, e):
        body = {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}
        return self._paginate("/getFleetStateLogs", body, "state_logs", MAX_LIMIT_DEFAULT)

    def get_drivers(self, cid, s, e):
        body = {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}
        return self._paginate("/getDrivers", body, "drivers", MAX_LIMIT_DEFAULT)

    def get_vehicles(self, cid, s, e):
        body = {"company_id": cid, "company_ids": [cid], "start_ts": s, "end_ts": e}
        return self._paginate("/getVehicles", body, "vehicles", MAX_LIMIT_VEHICLES)


# ---------------------------------------------------------------------------
# Procesare: aplatizare dinamica + spargere data/ora
# ---------------------------------------------------------------------------

def date_chunks(start: datetime, end: datetime, chunk_days: int) -> Iterable[tuple[int, int]]:
    cur = start
    delta = timedelta(days=chunk_days)
    while cur < end:
        nxt = min(cur + delta, end)
        yield int(cur.timestamp()), int(nxt.timestamp())
        cur = nxt


def is_timestamp_column(name: str) -> bool:
    n = name.lower()
    return n.endswith(TS_SUFFIXES) or n.split(".")[-1] in TS_EXACT


def ts_base_name(name: str) -> str:
    """order_created_timestamp -> order_created ; created -> created ; ended_at -> ended_at"""
    for suf in TS_SUFFIXES:
        if name.lower().endswith(suf):
            return name[: -len(suf)]
    return name


def build_dataframe(records: list[dict], keep_raw_ts: bool = False) -> pd.DataFrame:
    """Aplatizeaza orice structura JSON intr-un tabel complet, pastrand EXACT
    ordinea campurilor din raspunsul API.
    - dict-uri imbricate -> coloane cu punct (ex: order_price.net_earnings)
    - liste/dict-uri ramase -> serializate JSON (nimic pierdut)
    - FIECARE timestamp unix -> doua coloane noi, chiar pe pozitia campului
      original: <camp>_date si <camp>_time (ora locala Bucuresti, FARA offset).
      Epoch-ul brut e inlocuit de cele doua coloane; foloseste keep_raw_ts=True
      ca sa pastrezi si valoarea numerica originala.
    """
    if not records:
        return pd.DataFrame()

    df = pd.json_normalize(records, sep=".")

    # Serializeaza orice celula ramasa lista/dict (ex: order_stops, active_categories)
    for col in df.columns:
        if df[col].apply(lambda v: isinstance(v, (list, dict))).any():
            df[col] = df[col].apply(
                lambda v: json.dumps(v, ensure_ascii=False) if isinstance(v, (list, dict)) else v)

    # Sparge FIECARE timestamp in <camp>_date + <camp>_time, pe pozitia originala
    new_order: list[str] = []
    for col in list(df.columns):
        if is_timestamp_column(col):
            base = ts_base_name(col)
            secs = pd.to_numeric(df[col], errors="coerce")
            secs = secs.where(secs > 0)  # 0/null -> gol
            dt = pd.to_datetime(secs, unit="s", utc=True).dt.tz_convert(LOCAL_TZ)
            df[f"{base}_date"] = dt.dt.strftime("%Y-%m-%d")
            df[f"{base}_time"] = dt.dt.strftime("%H:%M:%S")
            if keep_raw_ts:
                new_order.append(col)
            new_order += [f"{base}_date", f"{base}_time"]
        else:
            new_order.append(col)

    return df[new_order]


def build_stops_table(orders: list[dict]) -> pd.DataFrame:
    """Tabel separat, un rand per oprire, legat prin order_reference (fidelitate geo completa)."""
    rows = []
    for o in orders:
        ref = o.get("order_reference")
        for i, s in enumerate(o.get("order_stops") or []):
            row = {"order_reference": ref, "stop_index": i}
            row.update(s if isinstance(s, dict) else {"value": s})
            rows.append(row)
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

def save_df(df: pd.DataFrame, name: str, out_dir: Path) -> None:
    if df is None or df.empty:
        log.info("  (gol) %s", name)
        return
    df.to_csv(out_dir / f"{name}.csv", index=False, encoding="utf-8-sig")
    try:
        df.to_parquet(out_dir / f"{name}.parquet", index=False)
    except Exception as exc:
        log.debug("Parquet sarit pt %s: %s", name, exc)
    log.info("  Salvat %s (%d randuri, %d coloane)", name, len(df), df.shape[1])


def save_raw(records: list[dict], name: str, raw_dir: Path) -> None:
    if not records:
        return
    (raw_dir / f"{name}.json").write_text(
        json.dumps(records, ensure_ascii=False, indent=2), encoding="utf-8")


# ---------------------------------------------------------------------------
# Credentiale din folderul flotei
# ---------------------------------------------------------------------------

def load_credentials(fleet_dir: Path) -> tuple[str, str]:
    env_path = fleet_dir / "myKey.env"
    creds: dict[str, str] = {}
    if env_path.exists():
        try:
            from dotenv import dotenv_values
            creds = {k: v for k, v in dotenv_values(env_path).items() if v}
        except ImportError:
            for line in env_path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    creds[k.strip()] = v.strip()
    cid = creds.get("BOLT_CLIENT_ID") or os.environ.get("BOLT_CLIENT_ID")
    secret = creds.get("BOLT_CLIENT_SECRET") or os.environ.get("BOLT_CLIENT_SECRET")
    if not cid or not secret:
        raise SystemExit(
            f"Nu gasesc credentialele. Creeaza fisierul:\n  {env_path}\n"
            "cu continutul:\n  BOLT_CLIENT_ID=...\n  BOLT_CLIENT_SECRET=...\n"
            "(le generezi din fleets.bolt.eu -> Settings -> API)"
        )
    return cid, secret


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Extractor complet Bolt Fleet Integration")
    p.add_argument("--fleet", default=".", help="Folderul flotei (contine myKey.env). Aici se scriu rezultatele.")
    p.add_argument("--start", help="Data de start YYYY-MM-DD (implicit: ~2 ani in urma)")
    p.add_argument("--end", help="Data de final YYYY-MM-DD (implicit: azi)")
    p.add_argument("--days-back", type=int, help="Alternativa la --start: ultimele N zile")
    p.add_argument("--chunk-days", type=int, default=DEFAULT_CHUNK_DAYS)
    p.add_argument("--filter-type", default="created", choices=["created", "price_review"])
    p.add_argument("--keep-raw-ts", action="store_true",
                   help="Pastreaza si coloanele timestamp brute (epoch), pe langa _date/_time")
    return p.parse_args()


def resolve_dates(args) -> tuple[datetime, datetime]:
    end = (datetime.strptime(args.end, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
           if args.end else datetime.now(LOCAL_TZ))
    if args.days_back:
        start = end - timedelta(days=args.days_back)
    elif args.start:
        start = datetime.strptime(args.start, "%Y-%m-%d").replace(tzinfo=LOCAL_TZ)
    else:
        start = end - timedelta(days=DEFAULT_LOOKBACK_DAYS)
    return start, end


def main() -> None:
    args = parse_args()
    fleet_dir = Path(args.fleet).expanduser().resolve()
    fleet_dir.mkdir(parents=True, exist_ok=True)

    cid_secret = load_credentials(fleet_dir)
    start, end = resolve_dates(args)

    run_ts = datetime.now(LOCAL_TZ).strftime("%Y%m%d_%H%M%S")
    out_dir = fleet_dir / f"extract_{run_ts}"
    raw_dir = out_dir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    log.info("Flota: %s", fleet_dir)
    log.info("Interval: %s -> %s | filtru: %s", start.date(), end.date(), args.filter_type)
    log.info("Iesire: %s", out_dir)

    client = BoltFleetClient(BoltAuth(*cid_secret))

    company_ids = client.get_companies()
    log.info("Companii: %s", company_ids)
    save_df(pd.DataFrame({"company_id": company_ids}), "companies", out_dir)

    orders_raw, logs_raw = [], []
    drivers_by_key: dict[Any, dict] = {}
    vehicles_by_key: dict[Any, dict] = {}

    for cidx in company_ids:
        log.info("=== Companie %s ===", cidx)
        for s_ts, e_ts in date_chunks(start, end, args.chunk_days):
            win = f"{datetime.fromtimestamp(s_ts, LOCAL_TZ).date()}..{datetime.fromtimestamp(e_ts, LOCAL_TZ).date()}"
            log.info("  Fereastra %s", win)
            try:
                orders_raw += client.get_orders(cidx, s_ts, e_ts, args.filter_type)
                logs_raw += client.get_state_logs(cidx, s_ts, e_ts)
                for d in client.get_drivers(cidx, s_ts, e_ts):
                    drivers_by_key[d.get("driver_uuid") or d.get("uuid") or d.get("id") or id(d)] = d
                for v in client.get_vehicles(cidx, s_ts, e_ts):
                    vehicles_by_key[v.get("uuid") or v.get("id") or v.get("car_id") or id(v)] = v
            except BoltAPIError as exc:
                if exc.code in (498805, 498806):
                    log.warning("  Fereastra %s sarita: %s", win, exc)
                    continue
                raise

    drivers_raw = list(drivers_by_key.values())
    vehicles_raw = list(vehicles_by_key.values())

    log.info("=== Salvez JSON brut (fidelitate completa) ===")
    save_raw(orders_raw, "orders", raw_dir)
    save_raw(logs_raw, "state_logs", raw_dir)
    save_raw(drivers_raw, "drivers", raw_dir)
    save_raw(vehicles_raw, "vehicles", raw_dir)

    log.info("=== Export tabele (toate campurile, ordinea din API) ===")
    save_df(build_dataframe(orders_raw, keep_raw_ts=args.keep_raw_ts), "orders", out_dir)
    save_df(build_stops_table(orders_raw), "order_stops", out_dir)
    save_df(build_dataframe(logs_raw, keep_raw_ts=args.keep_raw_ts), "state_logs", out_dir)
    save_df(build_dataframe(drivers_raw, keep_raw_ts=args.keep_raw_ts), "drivers", out_dir)
    save_df(build_dataframe(vehicles_raw, keep_raw_ts=args.keep_raw_ts), "vehicles", out_dir)

    log.info("Gata. Totul in: %s", out_dir)


def _pause() -> None:
    """Tine fereastra deschisa pana apesi ENTER (utila la dublu-click pe fisier)."""
    try:
        input("\n=== Gata. Apasa ENTER ca sa inchizi fereastra. ===\n")
    except EOFError:
        pass  # daca nu exista consola interactiva, nu blocheaza


if __name__ == "__main__":
    import traceback
    try:
        main()
    except SystemExit as e:
        # mesajele de configurare (ex: lipsa myKey.env) sunt trimise prin SystemExit
        if e.code not in (0, None):
            print(f"\n{e.code}")
    except Exception:
        print("\n!!! A aparut o eroare neasteptata:")
        traceback.print_exc()
    finally:
        _pause()
