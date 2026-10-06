EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q19_analiza_eficienta_pret_km_saptamanal_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS


WITH curse_eficienta AS (
  SELECT
    order_reference,
    -- Grupare pe inceput de saptamana (Luni)
    DATE_TRUNC(order_created_date, WEEK(MONDAY)) AS inceput_saptamana,
    order_price_net_earnings,
    ride_distance_km,
    
    -- Calculam lei pe km per cursa (doar pe distanta platita)
    SAFE_DIVIDE(order_price_net_earnings, ride_distance_km) AS lei_per_km_cursa
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE 
    order_status = 'finished'
    AND ride_distance_km > 0
)

SELECT
  inceput_saptamana,
  CONCAT('Sapt. ', FORMAT_DATE('%d-%b', inceput_saptamana)) AS eticheta_saptamana,
  
  -- Volum total de curse valide
  COUNT(order_reference) AS total_curse_finalizate,
  
  -- Numar si procent curse SUB 2.5 lei/km
  COUNTIF(lei_per_km_cursa < 2.5) AS numar_curse_sub_2_5_lei_km,
  ROUND(
    SAFE_DIVIDE(COUNTIF(lei_per_km_cursa < 2.5), COUNT(order_reference)) * 100, 
    1
  ) AS procent_curse_sub_2_5_lei_km,
  
  -- Numar si procent curse SUB 3.0 lei/km
  COUNTIF(lei_per_km_cursa < 3.0) AS numar_curse_sub_3_0_lei_km,
  ROUND(
    SAFE_DIVIDE(COUNTIF(lei_per_km_cursa < 3.0), COUNT(order_reference)) * 100, 
    1
  ) AS procent_curse_sub_3_0_lei_km,

  -- Indicator de referinta: Valoarea medie lei/km pe saptamana respectiva
  ROUND(AVG(lei_per_km_cursa), 2) AS medie_lei_per_km_saptamana,
  
  -- Medie agregata (Castig total / KM Totali). Adaugata ca extra.
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(ride_distance_km)), 2) AS medie_lei_per_km_saptamana_agregat

FROM 
  curse_eficienta
GROUP BY 
  inceput_saptamana,
  eticheta_saptamana
ORDER BY 
  inceput_saptamana DESC;
