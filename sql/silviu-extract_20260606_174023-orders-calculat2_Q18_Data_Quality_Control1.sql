SELECT 
  order_reference,
  order_status,
  order_price_net_earnings,
  ride_distance,
  ride_duration,
  to_client_duration,
  -- Calculăm viteza medie de rulare (km/h)
  SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0)) AS viteza_medie_kmh,
  
  -- Marcăm tipul de problemă găsită
  CASE 
    WHEN order_status = 'finished' AND order_price_net_earnings <= 0 THEN 'Cursă finalizată pe 0 lei sau minus'
    WHEN order_status = 'finished' AND ride_distance <= 0 THEN 'Cursă finalizată cu distanță zero'
    WHEN order_status = 'finished' AND ride_duration <= 0 THEN 'Cursă finalizată cu durată zero'
    WHEN order_status != 'finished' AND order_price_net_earnings > 15.0 THEN 'Cursă anulată cu câștig suspect de mare'
    WHEN SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0)) > 140.0 THEN 'Viteză SF (peste 140 km/h în oraș)'
    WHEN ride_duration > 180.0 THEN 'Cursă suspect de lungă (peste 3 ore)'
    ELSE 'OK'
  END AS diagnostic_problema
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  -- Filtrăm doar rândurile care încalcă regulile de mai sus
  (order_status = 'finished' AND (order_price_net_earnings <= 0 OR ride_distance <= 0 OR ride_duration <= 0))
  OR (order_status != 'finished' AND order_price_net_earnings > 15.0)
  OR (SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0)) > 140.0)
  OR (ride_duration > 180.0);