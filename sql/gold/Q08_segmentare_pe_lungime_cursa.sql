EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q08_segmentare_pe_lungime_cursa_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS


SELECT
  -- Construim sertarele de distanta pe baza kilometrilor efectivi ai cursei
  CASE
    WHEN ride_distance_km <= 3.0 THEN '1. Cursa Scurta (0 - 3 km)'
    WHEN ride_distance_km > 3.0 AND ride_distance_km <= 8.0 THEN '2. Cursa Medie (3 - 8 km)'
    ELSE '3. Cursa Lunga (peste 8 km)'
  END AS tip_cursa,
  
  COUNT(order_reference) AS volum_curse,
  
  -- Suma veniturilor nete pentru fiecare segment de cursa
  ROUND(SUM(order_price_net_earnings), 1) AS venituri_totale_lei,
  
  -- Analiza profitabilitatii pe timp (Bani raportati la Timp) per cursa
  ROUND(AVG(lei_per_min_total), 1) AS venit_mediu_per_minut_per_cursa,
  
  -- Analiza de uzura a masinii (Bani raportati la Distanta) per cursa
  ROUND(AVG(lei_per_km_total), 1) AS venit_mediu_per_km_per_cursa,

  -- Variantele agregate (Bani totali / Timp total per categorie si Bani totali / Distanta totala per categorie)
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_duration_minutes)), 1) AS venit_agregat_per_minut,
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_distance_km)), 1) AS venit_agregat_per_km,
  
  -- Cat ai condus in medie ca sa ajungi la aceste curse (km morti)
  ROUND(AVG(pickup_distance_km), 1) AS medie_km_preluare

FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  order_status = 'finished'
GROUP BY 
  tip_cursa
ORDER BY 
  tip_cursa ASC;
