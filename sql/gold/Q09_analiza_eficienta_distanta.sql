EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q09_analiza_eficienta_distanta_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

SELECT
  EXTRACT(HOUR FROM order_created_time) AS ora_zi,
  COUNT(order_reference) AS numar_total_curse,
  
  -- Distantele medii inregistrate
  ROUND(AVG(pickup_distance_km), 1) AS medie_km_preluare_gol,
  ROUND(AVG(ride_distance_km), 1) AS medie_km_cursa_platit,
  
  -- Procentul de kilometri morti din totalul unei comenzi (preluare + cursa)
  ROUND(
    AVG(SAFE_DIVIDE(pickup_distance_km, total_trip_distance_km) * 100), 
    1
  ) AS procent_km_morti_mediu_per_cursa,

  -- Varianta Agregata pentru procent km morti (Total KM Preluare / Total KM Cursa+Preluare) - de multe ori mai relevanta
  ROUND(
    SAFE_DIVIDE(SUM(pickup_distance_km), SUM(total_trip_distance_km)) * 100, 
    1
  ) AS procent_km_morti_agregat,
  
  -- Indicatorul principal de eficienta pe distanta
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km,
  
  -- Noul indicator adaugat pentru eficienta pe timp (Bani/Minut)
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut,

  -- Variantele Agregate (Bani/KM si Bani/Min)
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_distance_km)), 1) AS medie_lei_per_km_agregat,
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_duration_minutes)), 1) AS medie_lei_per_minut_agregat
  
FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  order_status = 'finished'
GROUP BY 
  ora_zi
ORDER BY 
  procent_km_morti_agregat DESC; -- Am actualizat sortarea sa se bazeze pe coloana agregata
