WITH date_timp_online AS (
  -- Pasul 1: Calculam secundele online si secundele active pe fiecare zi din state_logs
  SELECT
    created_date AS data_zi,
    
    -- Secunde totale online (waiting + has_order)
    SUM(
      CASE 
        WHEN state IN ('waiting_orders', 'has_order') AND secunde_in_stare IS NOT NULL THEN secunde_in_stare 
        ELSE 0 
      END
    ) AS secunde_online_total,
    
    -- Secunde curse active (doar has_order)
    SUM(
      CASE 
        WHEN state = 'has_order' AND secunde_in_stare IS NOT NULL THEN secunde_in_stare 
        ELSE 0 
      END
    ) AS secunde_cursa_activa
  FROM (
    SELECT
      created_date,
      state,
      TIMESTAMP_DIFF(
        LEAD(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', CONCAT(created_date, ' ', created_time))) 
          OVER(PARTITION BY driver_uuid ORDER BY created_date ASC, created_time ASC),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', CONCAT(created_date, ' ', created_time)),
        SECOND
      ) AS secunde_in_stare
    FROM 
      `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-state_logs`
  )
  GROUP BY 
    data_zi
),

date_curse AS (
  -- Pasul 2: Calculam incasarile si numarul de curse pe fiecare zi
  SELECT
    order_created_date AS data_zi,
    SUM(order_price_net_earnings) AS total_suma_incasata,
    COUNT(order_reference) AS numar_curse_finalizate
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
  WHERE 
    order_status = 'finished'
  GROUP BY 
    data_zi
)

-- Pasul 3: Unim datele si asezam coloanele in ordinea ceruta
SELECT
  c.data_zi,
  
  ROUND(c.total_suma_incasata, 1) AS total_suma_incasata_lei,
  
  ROUND(
    SAFE_DIVIDE(
      c.total_suma_incasata, 
      SAFE_DIVIDE(t.secunde_online_total, 3600.0)
    ), 
    1
  ) AS castig_net_ora_lei,
  
  c.numar_curse_finalizate,
  
  CONCAT(
    CAST(FLOOR(t.secunde_online_total / 3600) AS STRING), 'h ',
    CAST(FLOOR(MOD(t.secunde_online_total, 3600) / 60) AS STRING), 'min'
  ) AS timp_online_total,
  
  -- Coloana adaugata: Timpul de cursa efectiva formatat (has_order)
  CONCAT(
    CAST(FLOOR(t.secunde_cursa_activa / 3600) AS STRING), 'h ',
    CAST(FLOOR(MOD(t.secunde_cursa_activa, 3600) / 60) AS STRING), 'min'
  ) AS timp_cursa_activa,
  
  -- Coloana adaugata: Gradul de utilizare procentual
  ROUND(SAFE_DIVIDE(t.secunde_cursa_activa, t.secunde_online_total) * 100, 1) AS procent_utilizare

FROM 
  date_curse c
LEFT JOIN 
  date_timp_online t ON c.data_zi = t.data_zi
ORDER BY 
  c.data_zi DESC;