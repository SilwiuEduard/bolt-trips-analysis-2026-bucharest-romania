SELECT 
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_total_curse,
  
  -- Indicatorii de eficiență rotunjiți la o singură cifră după virgulă
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut,
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km,
  ROUND(SUM(order_price_net_earnings), 1) AS castiguri_totale_lei
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  ora_zi ASC;