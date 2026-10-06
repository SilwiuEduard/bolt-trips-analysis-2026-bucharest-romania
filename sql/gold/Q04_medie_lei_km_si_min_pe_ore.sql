EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q04_medie_lei_km_si_min_pe_ore_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

SELECT 
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_total_curse,
  
  -- Sume absolute
  ROUND(SUM(order_price_net_earnings), 1) AS castiguri_totale_lei,

  -- Medii simple (media per cursa)
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut_per_cursa,
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km_per_cursa,

  -- Medii agregate (castig total / distanta sau timp total). Mai robuste.
  ROUND(
    SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_duration_minutes)), 
    1
  ) AS medie_lei_per_minut_agregat,
  ROUND(
    SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_distance_km)), 
    1
  ) AS medie_lei_per_km_agregat

FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  ora_zi ASC;
