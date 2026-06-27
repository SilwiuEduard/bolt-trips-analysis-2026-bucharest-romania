SELECT
  -- Construim sertarele de distanta pe baza kilometrilor efectivi ai cursei
  CASE
    WHEN ride_distance <= 3.0 THEN '1. Cursa Scurta (0 - 3 km)'
    WHEN ride_distance > 3.0 AND ride_distance <= 8.0 THEN '2. Cursa Medie (3 - 8 km)'
    ELSE '3. Cursa Lunga (peste 8 km)'
  END AS tip_cursa,
  
  COUNT(order_reference) AS volum_curse,
  
  -- Suma veniturilor nete pentru fiecare segment de cursa
  ROUND(SUM(order_price_net_earnings), 1) AS venituri_totale_lei,
  
  -- Analiza profitabilitatii pe timp (Bani raportati la Timp)
  ROUND(AVG(lei_per_min_total), 1) AS venit_mediu_per_minut,
  
  -- Analiza de uzura a masinii (Bani raportati la Distanta)
  ROUND(AVG(lei_per_km_total), 1) AS venit_mediu_per_km,
  
  -- Cat ai condus in medie ca sa ajungi la aceste curse (km morti)
  ROUND(AVG(to_client_distance), 1) AS medie_km_preluare

FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  order_status = 'finished'
GROUP BY 
  tip_cursa
ORDER BY 
  tip_cursa ASC;