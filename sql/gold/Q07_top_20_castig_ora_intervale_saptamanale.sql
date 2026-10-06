EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q07_top_20_castig_ora_intervale_saptamanale_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

-- Top 20 de intervale saptamanale (Zi din saptamana + Ora) din tot istoricul, sortate dupa cel mai bun castig_net_ora_lei
WITH date_timp_online AS (
  SELECT
    FORMAT_DATE('%A', created_date) AS zi_saptamana,
    EXTRACT(HOUR FROM created_time) AS ora_zi,
    SUM(secunde_in_stare) AS secunde_online_total
  FROM (
    SELECT
      EXTRACT(DATE FROM TIMESTAMP_SECONDS(created) AT TIME ZONE 'Europe/Bucharest') AS created_date,
      EXTRACT(TIME FROM TIMESTAMP_SECONDS(created) AT TIME ZONE 'Europe/Bucharest') AS created_time,
      state,
      -- Deoarece 'created' e in secunde Unix, putem face o simpla scadere matematica!
      LEAD(created) OVER(PARTITION BY driver_uuid ORDER BY created ASC) - created AS secunde_in_stare
    FROM 
      `woven-howl-489214-k5.bronze_bolt_trips_silviu.bronze_state_logs_silviu_raw`
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
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE 
    order_status = 'finished'
  GROUP BY 
    zi_saptamana, ora_zi
)

SELECT
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
  AND c.numar_curse > 5 
ORDER BY 
  castig_net_ora_lei DESC
LIMIT 20;
