SELECT
  -- Impartim in doua categorii clare pe baza metodei de plata
  CASE 
    WHEN payment_method = 'cash' THEN '1. Curse CASH (Casa de marcat)'
    WHEN payment_method IN ('in_app', 'business') THEN '2. Curse CARD (In-App / Business)'
    ELSE '3. Altele / Nespecificat'
  END AS tip_incasare,

  -- Numarul total de curse din fiecare categorie
  COUNT(order_reference) AS volum_curse,

  -- Banii totali generati (venit net din aplicatie)
  ROUND(SUM(order_price_net_earnings), 1) AS incasari_totale_lei,

  -- Indicatori medii de performanta si uzura per categorie
  ROUND(AVG(order_price_net_earnings), 1) AS medie_lei_per_cursa,
  ROUND(AVG(lei_per_min_total), 1) AS venit_mediu_per_minut,
  ROUND(AVG(lei_per_km_total), 1) AS venit_mediu_per_km,
  
  -- Lungimea medie a curselor si a preluarilor
  ROUND(AVG(ride_distance), 1) AS medie_km_cursa_platit,
  ROUND(AVG(to_client_distance), 1) AS medie_km_preluare

FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  order_status = 'finished'
  AND order_created_date >= '2026-03-31' -- Filtru incepand cu ziua in care ai avut casa de marcat
GROUP BY 
  tip_incasare
ORDER BY 
  tip_incasare ASC;