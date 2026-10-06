EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q05_medie_lei_km_si_min_pe_zile_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH date_pregatite AS (
  SELECT 
    order_reference,
    order_price_net_earnings,
    lei_per_min_total,
    lei_per_km_total,
    total_trip_duration_minutes,
    total_trip_distance_km,
    
    -- Traducem zilele in limba romana (fara diacritice)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 'Luni'
      WHEN 3 THEN 'Marti'
      WHEN 4 THEN 'Miercuri'
      WHEN 5 THEN 'Joi'
      WHEN 6 THEN 'Vineri'
      WHEN 7 THEN 'Sambata'
      WHEN 1 THEN 'Duminica'
    END AS zi_saptamana,
    
    -- Sortare cronologica (Luni -> Duminica)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 1
      WHEN 3 THEN 2
      WHEN 4 THEN 3
      WHEN 5 THEN 4
      WHEN 6 THEN 5
      WHEN 7 THEN 6
      WHEN 1 THEN 7
    END AS ordine_sortare
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE 
    order_status = 'finished'
)

-- Agregam strict la nivel de zi
SELECT 
  zi_saptamana,
  COUNT(order_reference) AS numar_total_curse,
  ROUND(SUM(order_price_net_earnings), 1) AS castiguri_totale_lei,
  
  -- Media pe fiecare cursa in parte
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut_per_cursa,
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km_per_cursa,

  -- Viteza agregata a zilei (cea mai precisa pentru business)
  ROUND(
    SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_duration_minutes)), 
    1
  ) AS medie_lei_per_minut_agregat,
  ROUND(
    SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_distance_km)), 
    1
  ) AS medie_lei_per_km_agregat

FROM 
  date_pregatite
GROUP BY 
  zi_saptamana, 
  ordine_sortare
ORDER BY 
  ordine_sortare ASC;
