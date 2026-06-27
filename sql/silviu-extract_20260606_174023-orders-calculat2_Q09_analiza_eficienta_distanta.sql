SELECT
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_total_curse,
  
  -- Distantele medii inregistrate
  ROUND(AVG(to_client_distance), 1) AS medie_km_preluare_gol,
  ROUND(AVG(ride_distance), 1) AS medie_km_cursa_platit,
  
  -- Procentul de kilometri morti din totalul unei comenzi (preluare + cursa)
  ROUND(
    AVG(to_client_distance / (to_client_distance + ride_distance) * 100), 
    1
  ) AS procent_km_morti,
  
  -- Indicatorul principal de eficienta pe distanta
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km,
  
  -- Noul indicator adaugat pentru eficienta pe timp (Bani/Minut)
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut
  
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  procent_km_morti DESC; -- Sorteaza descrescator, punand primele orele cele mai neficiente