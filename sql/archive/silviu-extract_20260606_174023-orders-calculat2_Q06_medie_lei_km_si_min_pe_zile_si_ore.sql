WITH date_timp_online AS (
  -- Pasul 1: Calculam secundele online totale pe fiecare zi si ora din saptamana
  SELECT
    FORMAT_DATE('%A', created_date) AS zi_saptamana,
    EXTRACT(HOUR FROM created_time) AS ora_zi,
    SUM(secunde_in_stare) AS secunde_online_total
  FROM (
    SELECT
      created_date,
      created_time,
      state,
      TIMESTAMP_DIFF(
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
  -- Pasul 2: Calculam volumul, incasarile totale si mediile specifice din raportul Q8
  SELECT
    FORMAT_DATE('%A', order_created_date) AS zi_saptamana,
    EXTRACT(HOUR FROM order_created_time) AS ora_zi,
    COUNT(order_reference) AS total_curse_finalizate,
    SUM(order_price_net_earnings) AS total_incasat_lei,
    
    -- Metricile de baza din Q8 (medie lei pe minut de cursa si pe kilometru)
    ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut_cursa,
    ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km_cursa
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
  WHERE 
    order_status = 'finished'
  GROUP BY 
    zi_saptamana, ora_zi
)

-- Pasul 3: Combinarea finala a metricilor si ordonarea saptamanala cronologica
SELECT
  CASE c.zi_saptamana
    WHEN 'Monday' THEN '1. Luni'
    WHEN 'Tuesday' THEN '2. Marti'
    WHEN 'Wednesday' THEN '3. Miercuri'
    WHEN 'Thursday' THEN '4. Joi'
    WHEN 'Friday' THEN '5. Vineri'
    WHEN 'Saturday' THEN '6. Sambata'
    WHEN 'Sunday' THEN '7. Duminica'
  END AS zi_lucru,
  
  c.ora_zi AS interval_ora,
  c.total_curse_finalizate,
  ROUND(c.total_incasat_lei, 1) AS total_incasat_lei,
  
  -- Coloana adaugata 1: Timpul online total in acea fereastra orara din istoric
  CONCAT(
    CAST(FLOOR(t.secunde_online_total / 3600) AS STRING), 'h ',
    CAST(FLOOR(MOD(t.secunde_online_total, 3600) / 60) AS STRING), 'min'
  ) AS timp_online_total,

  -- Coloana adaugata 2: Castigul net real pe ora de stat online
  ROUND(
    SAFE_DIVIDE(c.total_incasat_lei, SAFE_DIVIDE(t.secunde_online_total, 3600.0)), 
    1
  ) AS castig_net_ora_lei,
  
  -- Metricile originale din Q8 repuse in tabel pentru comparatie directa
  c.medie_lei_per_minut_cursa,
  c.medie_lei_per_km_cursa

FROM 
  date_curse c
INNER JOIN 
  date_timp_online t ON c.zi_saptamana = t.zi_saptamana AND c.ora_zi = t.ora_zi
WHERE 
  t.secunde_online_total > 0
ORDER BY 
  zi_lucru ASC, 
  interval_ora ASC;