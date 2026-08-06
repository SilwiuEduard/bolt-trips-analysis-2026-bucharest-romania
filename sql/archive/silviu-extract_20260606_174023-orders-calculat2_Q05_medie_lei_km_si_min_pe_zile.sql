WITH date_pregatite AS (
  SELECT 
    order_reference,
    order_price_net_earnings,
    lei_per_min_total,
    lei_per_km_total,
    
    -- Traducem zilele în limba română
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 'Luni'
      WHEN 3 THEN 'Marti'
      WHEN 4 THEN 'Miercuri'
      WHEN 5 THEN 'Joi'
      WHEN 6 THEN 'Vineri'
      WHEN 7 THEN 'Sambata'
      WHEN 1 THEN 'Duminica'
    END AS zi_saptamana,
    
    -- Sortare cronologică (Luni -> Duminică)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 1
      WHEN 3 THEN 2
      WHEN 4 THEN 3
      WHEN 5 THEN 4
      WHEN 6 THEN 5
      WHEN 7 THEN 6
      WHEN 1 THEN 7
    END AS ordine_sortare
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
  WHERE 
    order_status = 'finished'
)

-- Agregăm strict la nivel de zi
SELECT 
  zi_saptamana,
  COUNT(order_reference) AS numar_total_curse,
  ROUND(AVG(lei_per_min_total), 1) AS medie_lei_per_minut,
  ROUND(AVG(lei_per_km_total), 1) AS medie_lei_per_km,
  ROUND(SUM(order_price_net_earnings), 1) AS castiguri_totale_lei
FROM 
  date_pregatite
GROUP BY 
  zi_saptamana, 
  ordine_sortare
ORDER BY 
  ordine_sortare ASC;