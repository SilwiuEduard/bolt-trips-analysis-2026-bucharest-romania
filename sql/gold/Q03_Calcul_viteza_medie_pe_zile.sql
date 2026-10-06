EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q03_Calcul_viteza_medie_pe_zile_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH date_pregatite AS (
  SELECT 
    order_reference,
    ride_distance_km,
    ride_duration_minutes,
    
    -- Pasul 1: Definim numele zilei in limba romana (fara diacritice)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 'Luni'
      WHEN 3 THEN 'Marti'
      WHEN 4 THEN 'Miercuri'
      WHEN 5 THEN 'Joi'
      WHEN 6 THEN 'Vineri'
      WHEN 7 THEN 'Sambata'
      WHEN 1 THEN 'Duminica'
    END AS zi_saptamana,
    
    -- Pasul 2: Cream o coloana numerica simpla pentru sortare (Luni = 1, Duminica = 7)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 1 -- Luni
      WHEN 3 THEN 2 -- Marti
      WHEN 4 THEN 3 -- Miercuri
      WHEN 5 THEN 4 -- Joi
      WHEN 6 THEN 5 -- Vineri
      WHEN 7 THEN 6 -- Sambata
      WHEN 1 THEN 7 -- Duminica
    END AS ordine_sortare
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE 
    order_status = 'finished'
)

-- Pasul 3: Facem agregarea finala pe datele deja prelucrate
SELECT 
  zi_saptamana,
  COUNT(order_reference) AS numar_curse_finalizate,
  
  -- Media vitezelor individuale
  ROUND(
    AVG(SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0))), 
    1
  ) AS viteza_medie_kmh_per_cursa,

  -- Viteza agregata a zilei (mai potrivita pentru trafic)
  ROUND(
    SAFE_DIVIDE(SUM(ride_distance_km), SUM(SAFE_DIVIDE(ride_duration_minutes, 60.0))), 
    1
  ) AS viteza_medie_kmh_agregata

FROM 
  date_pregatite
GROUP BY 
  zi_saptamana, 
  ordine_sortare
ORDER BY 
  ordine_sortare ASC;
