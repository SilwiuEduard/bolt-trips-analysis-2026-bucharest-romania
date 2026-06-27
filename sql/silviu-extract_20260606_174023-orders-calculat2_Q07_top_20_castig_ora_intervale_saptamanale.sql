-- Top 20 de intervale saptamunale (Zi din saptamana + Ora) din tot istoricul, sortate dupa cel mai bun castig_net_ora_lei
WITH date_timp_online AS (
  SELECT
    FORMAT_DATE('%A', created_date) AS zi_saptamana,
    -- Corectat: Extragem ora direct, fara PARSE_TIME, deoarece coloana este deja de tip TIME
    EXTRACT(HOUR FROM created_time) AS ora_zi,
    SUM(secunde_in_stare) AS secunde_online_total
  FROM (
    SELECT
      created_date,
      created_time,
      state,
      TIMESTAMP_DIFF(
        -- Am adaugat CAST pentru created_time ca sa poata fi unit corect in CONCAT ca STRING
        LEAD(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', CONCAT(created_date, ' ', CAST(created_time AS STRING)))) 
          OVER(PARTITION BY driver_uuid ORDER BY created_date ASC, created_time ASC),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', CONCAT(created_date, ' ', CAST(created_time AS STRING))),
        SECOND
      ) AS secunde_in_stare
    FROM 
      `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-state_logs`
  )
  WHERE state IN ('waiting_orders', 'has_order') AND secunde_in_stare IS NOT NULL
  GROUP BY zi_saptamana, ora_zi
),

date_curse AS (
  SELECT
    FORMAT_DATE('%A', order_created_date) AS zi_saptamana,
    EXTRACT(HOUR FROM order_created_time) AS ora_zi,
    SUM(order_price_net_earnings) AS total_incasat,
    COUNT(order_reference) AS numar_curse
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
  WHERE 
    order_status = 'finished'
  GROUP BY 
    zi_saptamana, ora_zi
)

SELECT
  -- Traducem zilele in romana pentru lizibilitate
  CASE c.zi_saptamana
    WHEN 'Monday' THEN 'Luni'
    WHEN 'Tuesday' THEN 'Marti'
    WHEN 'Wednesday' THEN 'Miercuri'
    WHEN 'Thursday' THEN 'Joi'
    WHEN 'Friday' THEN 'Vineri'
    WHEN 'Saturday' THEN 'Sambata'
    WHEN 'Sunday' THEN 'Duminica'
  END AS zi,
  c.ora_zi AS interval_ora,
  c.numar_curse AS total_curse_istoric,
  ROUND(c.total_incasat, 1) AS incasari_totale_lei,
  
  -- Castigul pur pe ora pentru acest interval specific
  ROUND(
    SAFE_DIVIDE(c.total_incasat, SAFE_DIVIDE(t.secunde_online_total, 3600.0)), 
    1
  ) AS castig_net_ora_lei

FROM 
  date_curse c
INNER JOIN 
  date_timp_online t ON c.zi_saptamana = t.zi_saptamana AND c.ora_zi = t.ora_zi
WHERE 
  t.secunde_online_total > 0 
  AND c.numar_curse > 5 -- Filtram ferestrele accidentale (vrem doar intervale cu volum relevant)
ORDER BY 
  castig_net_ora_lei DESC
LIMIT 20;