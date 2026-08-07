CREATE OR REPLACE VIEW `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders` AS

WITH raw_orders AS (
  SELECT * FROM `woven-howl-489214-k5.bronze_bolt_trips_silviu.bronze_orders_silviu_raw`
),

orders_with_datetimes AS (
  SELECT
    order_reference,
    driver_uuid,
    
    -- 1. Governance & PII (Anonimizare GDPR)
    TO_HEX(SHA256(driver_uuid)) AS driver_uuid_hash,
    TO_HEX(SHA256(partner_uuid)) AS partner_uuid_hash,

    vehicle_model,
    payment_method,
    order_status,

    -- Curatare diacritice pe campurile de text (a, i, a, s, t)
    REGEXP_REPLACE(TRANSLATE(driver_cancelled_reason, 'ăâîșțĂÂÎȘȚşţŞŢ', 'aaisaAAISTstST'), r'[^\x00-\x7F]', '') AS driver_cancelled_reason,
    REGEXP_REPLACE(TRANSLATE(price_review_reason, 'ăâîșțĂÂÎȘȚşţŞŢ', 'aaisaAAISTstST'), r'[^\x00-\x7F]', '') AS price_review_reason,
    REGEXP_REPLACE(TRANSLATE(pickup_address, 'ăâîșțĂÂÎȘȚşţŞŢ', 'aaisaAAISTstST'), r'[^\x00-\x7F]', '') AS pickup_address,
    REGEXP_REPLACE(TRANSLATE(destination_address, 'ăâîșțĂÂÎȘȚşţŞŢ', 'aaisaAAISTstST'), r'[^\x00-\x7F]', '') AS destination_address,

    is_scheduled,
    is_optional,

    -- 2. Conversie Timestamp Secunde -> DATETIME (Europe/Bucharest)
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_created_timestamp AS INT64)), 'Europe/Bucharest')) AS order_created_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_accepted_timestamp AS INT64)), 'Europe/Bucharest')) AS order_accepted_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_pickup_timestamp AS INT64)), 'Europe/Bucharest')) AS order_pickup_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_drop_off_timestamp AS INT64)), 'Europe/Bucharest')) AS order_drop_off_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_finished_timestamp AS INT64)), 'Europe/Bucharest')) AS order_finished_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_cancelled_timestamp AS INT64)), 'Europe/Bucharest')) AS order_cancelled_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(order_no_show_timestamp AS INT64)), 'Europe/Bucharest')) AS order_no_show_datetime,
    PARSE_DATETIME('%Y-%m-%d %H:%M:%S', FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', TIMESTAMP_SECONDS(CAST(payment_confirmed_timestamp AS INT64)), 'Europe/Bucharest')) AS payment_confirmed_datetime,

    -- 3. Financiare Redenumite & Safe Cast (2 zecimale)
    ROUND(SAFE_CAST(order_price_ride_price AS NUMERIC), 2) AS order_price_ride_price,
    ROUND(SAFE_CAST(order_price_net_earnings AS NUMERIC), 2) AS order_price_net_earnings,
    ROUND(SAFE_CAST(order_price_commission AS NUMERIC), 2) AS order_price_commission,
    ROUND(SAFE_CAST(order_price_booking_fee AS NUMERIC), 2) AS order_price_booking_fee,
    ROUND(SAFE_CAST(order_price_cancellation_fee AS NUMERIC), 2) AS order_price_cancellation_fee,
    ROUND(SAFE_CAST(order_price_cash_discount AS NUMERIC), 2) AS order_price_cash_discount,
    ROUND(SAFE_CAST(order_price_in_app_discount AS NUMERIC), 2) AS order_price_in_app_discount,
    ROUND(SAFE_CAST(order_price_tip AS NUMERIC), 2) AS order_price_tip,
    ROUND(SAFE_CAST(order_price_toll_fee AS NUMERIC), 2) AS order_price_toll_fee,

    category_info_name,
    category_info_seats,
    category_info_vehicle_type,

    -- 4. Distante brute (km)
    ROUND(SAFE_DIVIDE(ride_distance, 1000.0), 2) AS ride_distance_km,
    ROUND(SAFE_DIVIDE(road_distance_at_matching, 1000.0), 2) AS pickup_distance_km,
    ROUND(SAFE_DIVIDE(predicted_ride_distance, 1000.0), 2) AS predicted_ride_distance_km,

    order_stops,
    SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', ingestion_timestamp) AS ingestion_datetime

  FROM raw_orders
),

orders_with_overlap AS (
  SELECT
    *,
    -- Logica de Suprapunere (Overlapping Dispatch)
    LAST_VALUE(
      CASE 
        WHEN order_accepted_datetime IS NOT NULL 
          AND order_status = 'finished'
        THEN order_drop_off_datetime 
      END IGNORE NULLS
    ) OVER (
      PARTITION BY driver_uuid 
      ORDER BY order_created_datetime
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS previous_drop_off_datetime
  FROM orders_with_datetimes
),

calculated_metrics AS (
  SELECT
    *,
    -- Distanta totala & Diferenta fata de estimarea Bolt
    ROUND(COALESCE(ride_distance_km, 0) + COALESCE(pickup_distance_km, 0), 2) AS total_trip_distance_km,
    ROUND(ride_distance_km - predicted_ride_distance_km, 2) AS dif_distance_vs_predicted,

    -- Durata Cursa in Secunde
    DATETIME_DIFF(order_drop_off_datetime, order_pickup_datetime, SECOND) AS ride_duration_seconds,

    -- Durata Preluare in Secunde (cu suprapunere)
    CASE 
      WHEN previous_drop_off_datetime IS NOT NULL 
        AND order_accepted_datetime IS NOT NULL 
        AND previous_drop_off_datetime > order_accepted_datetime
      THEN DATETIME_DIFF(order_pickup_datetime, previous_drop_off_datetime, SECOND)
      ELSE DATETIME_DIFF(order_pickup_datetime, order_accepted_datetime, SECOND)
    END AS pickup_duration_seconds

  FROM orders_with_overlap
),

final_transformations AS (
  SELECT
    *,
    -- Durata Totala Cursa + Preluare (Secunde)
    (COALESCE(ride_duration_seconds, 0) + COALESCE(pickup_duration_seconds, 0)) AS total_trip_duration_seconds,

    -- Durate in Minute
    ROUND(SAFE_DIVIDE(ride_duration_seconds, 60.0), 2) AS ride_duration_minutes,
    ROUND(SAFE_DIVIDE(pickup_duration_seconds, 60.0), 2) AS pickup_duration_minutes,
    ROUND(SAFE_DIVIDE((COALESCE(ride_duration_seconds, 0) + COALESCE(pickup_duration_seconds, 0)), 60.0), 2) AS total_trip_duration_minutes

  FROM calculated_metrics
)

SELECT
  -- Identificatori & Status
  order_reference,                                         -- 1
  payment_method,                                         -- 2
  order_status,                                           -- 3

  -- Perechi Data / Timp
  EXTRACT(DATE FROM order_created_datetime) AS order_created_date,      -- 4
  EXTRACT(TIME FROM order_created_datetime) AS order_created_time,      -- 5

  EXTRACT(DATE FROM order_accepted_datetime) AS order_accepted_date,    -- 6
  EXTRACT(TIME FROM order_accepted_datetime) AS order_accepted_time,    -- 7

  EXTRACT(DATE FROM order_pickup_datetime) AS order_pickup_date,        -- 8
  EXTRACT(TIME FROM order_pickup_datetime) AS order_pickup_time,        -- 9

  EXTRACT(DATE FROM order_drop_off_datetime) AS order_drop_off_date,    -- 10
  EXTRACT(TIME FROM order_drop_off_datetime) AS order_drop_off_time,    -- 11

  EXTRACT(DATE FROM order_finished_datetime) AS order_finished_date,    -- 12
  EXTRACT(TIME FROM order_finished_datetime) AS order_finished_time,    -- 13

  EXTRACT(DATE FROM payment_confirmed_datetime) AS payment_confirmed_date, -- 14
  EXTRACT(TIME FROM payment_confirmed_datetime) AS payment_confirmed_time, -- 15

  EXTRACT(DATE FROM order_no_show_datetime) AS order_no_show_date,      -- 16
  EXTRACT(TIME FROM order_no_show_datetime) AS order_no_show_time,      -- 17

  EXTRACT(DATE FROM order_cancelled_datetime) AS order_cancelled_date,  -- 18
  EXTRACT(TIME FROM order_cancelled_datetime) AS order_cancelled_time,  -- 19
  driver_cancelled_reason,                                -- 20

  -- Proprietati Cursa
  is_optional,                                            -- 21
  price_review_reason,                                    -- 22
  is_scheduled,                                           -- 23

  -- Distante (km)
  pickup_distance_km,                                     -- 24
  ride_distance_km,                                       -- 25
  total_trip_distance_km,                                 -- 26
  predicted_ride_distance_km,                             -- 27
  dif_distance_vs_predicted,                              -- 28

  -- Durate Formatate (text)
  CASE 
    WHEN pickup_duration_seconds IS NULL THEN NULL
    WHEN FLOOR(pickup_duration_seconds / 3600) > 0 THEN 
      CONCAT(CAST(FLOOR(pickup_duration_seconds / 3600) AS STRING), 'h ', CAST(FLOOR(MOD(pickup_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(pickup_duration_seconds, 60) AS STRING), 'sec')
    ELSE 
      CONCAT(CAST(FLOOR(MOD(pickup_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(pickup_duration_seconds, 60) AS STRING), 'sec')
  END AS pickup_duration_formatted,                       -- 29

  CASE 
    WHEN ride_duration_seconds IS NULL THEN NULL
    WHEN FLOOR(ride_duration_seconds / 3600) > 0 THEN 
      CONCAT(CAST(FLOOR(ride_duration_seconds / 3600) AS STRING), 'h ', CAST(FLOOR(MOD(ride_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(ride_duration_seconds, 60) AS STRING), 'sec')
    ELSE 
      CONCAT(CAST(FLOOR(MOD(ride_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(ride_duration_seconds, 60) AS STRING), 'sec')
  END AS ride_duration_formatted,                         -- 30

  CASE 
    WHEN total_trip_duration_seconds IS NULL THEN NULL
    WHEN FLOOR(total_trip_duration_seconds / 3600) > 0 THEN 
      CONCAT(CAST(FLOOR(total_trip_duration_seconds / 3600) AS STRING), 'h ', CAST(FLOOR(MOD(total_trip_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(total_trip_duration_seconds, 60) AS STRING), 'sec')
    ELSE 
      CONCAT(CAST(FLOOR(MOD(total_trip_duration_seconds, 3600) / 60) AS STRING), 'min ', CAST(MOD(total_trip_duration_seconds, 60) AS STRING), 'sec')
  END AS total_trip_duration_formatted,                   -- 31

  -- Durate in Minute
  pickup_duration_minutes,                                -- 32
  ride_duration_minutes,                                  -- 33
  total_trip_duration_minutes,                            -- 34

  -- Durate in Secunde
  pickup_duration_seconds,                                -- 35
  ride_duration_seconds,                                  -- 36
  total_trip_duration_seconds,                            -- 37

  -- Indicatori Rentabilitate (lei/km si lei/min)
  ROUND(SAFE_DIVIDE(order_price_net_earnings, ride_distance_km), 2) AS lei_per_km_ride,     -- 38
  ROUND(SAFE_DIVIDE(order_price_net_earnings, total_trip_distance_km), 2) AS lei_per_km_total, -- 39
  ROUND(SAFE_DIVIDE(order_price_net_earnings, ride_duration_minutes), 2) AS lei_per_min_ride,   -- 40
  ROUND(SAFE_DIVIDE(order_price_net_earnings, total_trip_duration_minutes), 2) AS lei_per_min_total, -- 41

  -- Financiare Detaliate
  order_price_ride_price,                                 -- 42
  order_price_net_earnings,                               -- 43
  order_price_commission,                                 -- 44
  order_price_booking_fee,                                -- 45
  order_price_cancellation_fee,                           -- 46
  order_price_cash_discount,                              -- 47
  order_price_in_app_discount,                            -- 48
  order_price_tip,                                        -- 49
  order_price_toll_fee,                                   -- 50

  -- Adrese & Opri
  pickup_address,                                         -- 51
  destination_address,                                    -- 52
  order_stops,                                            -- 53

  -- Categorie & Vehicul
  category_info_vehicle_type,                             -- 54
  category_info_seats,                                    -- 55
  category_info_name,                                     -- 56
  vehicle_model,                                          -- 57

  -- Anonimizare PII (GDPR)
  driver_uuid_hash,                                       -- 58
  partner_uuid_hash,                                      -- 59

  -- Timpi Nativi (DATETIME)
  order_created_datetime,                                 -- 60
  order_accepted_datetime,                                -- 61
  order_pickup_datetime,                                  -- 62
  order_drop_off_datetime,                                -- 63
  order_finished_datetime,                                -- 64
  order_cancelled_datetime,                               -- 65
  order_no_show_datetime,                                 -- 66
  payment_confirmed_datetime,                             -- 67

  -- Audit System
  ingestion_datetime                                      -- 68

FROM final_transformations;

-- update v1