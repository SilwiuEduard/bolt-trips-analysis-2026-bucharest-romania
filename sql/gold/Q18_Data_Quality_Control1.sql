EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q18_Data_Quality_Control1_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS


SELECT 
  order_reference,
  order_created_datetime, -- Adaugat pentru identificare rapida
  order_status,
  order_price_net_earnings,
  ride_distance_km,
  ride_duration_minutes,
  pickup_duration_minutes,
  
  -- Calculam viteza medie de rulare (km/h)
  ROUND(SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0)), 1) AS viteza_medie_kmh,
  
  -- Marcam tipul de problema gasita
  CASE 
    WHEN order_status = 'finished' AND COALESCE(order_price_net_earnings, 0) <= 0 THEN 'Cursa finalizata pe 0 lei sau minus'
    WHEN order_status = 'finished' AND COALESCE(ride_distance_km, 0) <= 0 THEN 'Cursa finalizata cu distanta zero'
    WHEN order_status = 'finished' AND COALESCE(ride_duration_minutes, 0) <= 0 THEN 'Cursa finalizata cu durata zero'
    WHEN order_status != 'finished' AND order_price_net_earnings > 15.0 THEN 'Cursa anulata cu castig suspect de mare'
    WHEN SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0)) > 140.0 THEN 'Viteza SF (peste 140 km/h in oras)'
    WHEN ride_duration_minutes > 180.0 THEN 'Cursa suspect de lunga (peste 3 ore)'
    ELSE 'OK'
  END AS diagnostic_problema
FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  -- Filtram doar randurile care incalca regulile de mai sus
  (order_status = 'finished' AND (COALESCE(order_price_net_earnings, 0) <= 0 OR COALESCE(ride_distance_km, 0) <= 0 OR COALESCE(ride_duration_minutes, 0) <= 0))
  OR (order_status != 'finished' AND order_price_net_earnings > 15.0)
  OR (SAFE_DIVIDE(ride_distance_km, SAFE_DIVIDE(ride_duration_minutes, 60.0)) > 140.0)
  OR (ride_duration_minutes > 180.0);
