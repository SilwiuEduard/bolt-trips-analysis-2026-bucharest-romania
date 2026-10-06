EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q01_Calcul_viteza_medie_curse_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

SELECT 
  order_reference,
  order_status,
  payment_method,
  
  -- Castig net (deja rotunjit la 1 zecimala in Silver)
  ROUND(order_price_net_earnings, 1) AS castig_net_lei,
  
  -- Distanta si durata cursei cu clientul
  ROUND(ride_distance_km, 1) AS ride_distance_km,
  ROUND(ride_duration_minutes, 1) AS ride_duration_min,
  
  -- Viteza medie (km/h) cu clientul in masina (max 1 zecimala)
  ROUND(
    SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0)), 
    1
  ) AS viteza_medie_kmh,
  
  -- Distanta si durata pana la client (preluare / pickup)
  ROUND(pickup_distance_km, 1) AS to_client_dist_km,
  ROUND(pickup_duration_minutes, 1) AS to_client_dur_min,
  
  -- Data, ora si adresele
  order_created_date,
  order_created_time,
  pickup_address,
  destination_address

FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`

WHERE order_status = 'finished'

ORDER BY 
  order_created_date DESC, 
  order_created_time DESC;
