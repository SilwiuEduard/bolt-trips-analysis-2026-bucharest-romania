EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q02_Calcul_viteza_medie_pe_ore_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

SELECT 
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_curse_finalizate,
  
  -- Media vitezelor individuale ale fiecarei curse
  ROUND(
    AVG(SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0))), 
    1
  ) AS viteza_medie_kmh_per_cursa,

  -- Viteza agregata a orei (distanta totala / durata totala din acea ora)
  -- Acest indicator e adesea mai robust pentru a masura traficul general al orasului
  ROUND(
    SAFE_DIVIDE(SUM(ride_distance_km), SUM(SAFE_DIVIDE(ride_duration_minutes, 60.0))), 
    1
  ) AS viteza_medie_kmh_agregata

FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  ora_zi ASC;
