SELECT 
  order_reference,
  order_status,
  payment_method,
  ROUND(order_price_net_earnings, 1) AS castig_net_lei,
  
  -- Blocul de distanțe și durate rotunjite la o singură zecimală
  ROUND(ride_distance, 1) AS ride_distance_km,
  ROUND(ride_duration, 1) AS ride_duration_min,
  
  -- COLOANA NOUĂ: Viteza medie (km/h) cu clientul în mașină, limitată la max 1 zecimală
  ROUND(
    SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0)), 
    1
  ) AS viteza_medie_kmh,
  
  -- Date utile pentru contextul preluării
  ROUND(to_client_distance, 1) AS to_client_dist_km,
  ROUND(to_client_duration, 1) AS to_client_dur_min,
  
  -- Timpul și Adresele
  order_created_date,
  order_created_time,
  pickup_address,
  destination_address
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`

WHERE order_status = 'finished'

ORDER BY 
  order_created_date DESC, 
  order_created_time DESC;