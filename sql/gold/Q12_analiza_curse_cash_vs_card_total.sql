EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q12_analiza_curse_cash_vs_card_total_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS


SELECT
  -- Impartim in doua categorii clare pe baza metodei de plata
  CASE 
    WHEN payment_method = 'cash' THEN '1. Curse CASH (Casa de marcat)'
    WHEN payment_method IN ('in_app','business') THEN '2. Curse CARD (In-App & Business)'
    ELSE '4. Altele / Nespecificat'
  END AS tip_incasare,

  -- Numarul total de curse din fiecare categorie
  COUNT(order_reference) AS volum_curse,

  -- Banii totali generati (venit net din aplicatie)
  ROUND(SUM(order_price_net_earnings), 1) AS incasari_totale_lei,

  -- Indicatori medii de performanta si uzura per categorie (mediile pe cursa)
  ROUND(AVG(order_price_net_earnings), 1) AS medie_lei_per_cursa,
  ROUND(AVG(lei_per_min_total), 1) AS venit_mediu_per_minut_per_cursa,
  ROUND(AVG(lei_per_km_total), 1) AS venit_mediu_per_km_per_cursa,

  -- Indicatorii agregati (recomandati pentru comparatii sigure)
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_duration_minutes)), 1) AS venit_agregat_per_minut,
  ROUND(SAFE_DIVIDE(SUM(order_price_net_earnings), SUM(total_trip_distance_km)), 1) AS venit_agregat_per_km,
  
  -- Lungimea medie a curselor si a preluarilor
  ROUND(AVG(ride_distance_km), 1) AS medie_km_cursa_platit,
  ROUND(AVG(pickup_distance_km), 1) AS medie_km_preluare

FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  order_status = 'finished'
  AND order_created_date >= '2026-03-31' -- Filtru incepand cu ziua in care ai avut casa de marcat
GROUP BY 
  tip_incasare
ORDER BY 
  tip_incasare ASC;
