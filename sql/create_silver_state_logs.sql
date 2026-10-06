CREATE OR REPLACE VIEW `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_state_logs` AS
WITH raw_logs AS (
  SELECT * FROM `woven-howl-489214-k5.bronze_bolt_trips_silviu.bronze_state_logs_silviu_raw`
),

calculated_logs AS (
  SELECT
    -- 1. Anonimizare GDPR pentru a putea face JOIN in siguranta cu silver_orders
    TO_HEX(SHA256(driver_uuid)) AS driver_uuid_hash,
    TO_HEX(SHA256(vehicle_uuid)) AS vehicle_uuid_hash,

    state,
    lat,
    lng,

    -- 2. Conversie UNIX Timestamp -> Data si Ora (Europe/Bucharest)
    EXTRACT(DATE FROM TIMESTAMP_SECONDS(created) AT TIME ZONE 'Europe/Bucharest') AS created_date,
    EXTRACT(TIME FROM TIMESTAMP_SECONDS(created) AT TIME ZONE 'Europe/Bucharest') AS created_time,
    DATETIME(TIMESTAMP_SECONDS(created), 'Europe/Bucharest') AS created_datetime,

    -- 3. Calcul durata in fiecare stare (in secunde)
    LEAD(created) OVER (PARTITION BY driver_uuid ORDER BY created ASC) - created AS secunde_in_stare,

    -- 4. Alte detalii (comenzi active, categorii)
    active_categories_main_name,
    active_categories_main_group,
    active_order_order_reference,

    -- 5. Audit
    SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', ingestion_timestamp) AS ingestion_datetime

  FROM raw_logs
)

SELECT * FROM calculated_logs;
