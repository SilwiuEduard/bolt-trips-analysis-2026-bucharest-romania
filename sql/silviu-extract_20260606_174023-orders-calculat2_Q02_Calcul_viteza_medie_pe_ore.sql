SELECT 
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_curse_finalizate,
  
  -- Calculăm viteza medie a curselor din acea oră și o rotunjim la o zecimală
  ROUND(
    AVG(SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0))), 
    1
  ) AS viteza_medie_kmh
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  ora_zi ASC;