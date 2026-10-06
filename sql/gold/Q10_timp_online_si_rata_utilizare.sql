EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q10_timp_online_si_rata_utilizare_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH date_timp_online AS (
  -- Pasul 1: Calculam secundele online si secundele active pe fiecare zi
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
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_state_logs`
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
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
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
  
  -- Timpul de cursa efectiva formatat (has_order)
  CONCAT(
    CAST(FLOOR(t.secunde_cursa_activa / 3600) AS STRING), 'h ',
    CAST(FLOOR(MOD(t.secunde_cursa_activa, 3600) / 60) AS STRING), 'min'
  ) AS timp_cursa_activa,
  
  -- Gradul de utilizare procentual
  ROUND(SAFE_DIVIDE(t.secunde_cursa_activa, t.secunde_online_total) * 100, 1) AS procent_utilizare

FROM 
  date_curse c
LEFT JOIN 
  date_timp_online t ON c.data_zi = t.data_zi
ORDER BY 
  c.data_zi DESC;
