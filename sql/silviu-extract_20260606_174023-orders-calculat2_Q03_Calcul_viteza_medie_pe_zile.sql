WITH date_pregatite AS (
  SELECT 
    order_reference,
    ride_distance,
    ride_duration,
    
    -- Pasul 1: Definim numele zilei în limba română
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 'Luni'
      WHEN 3 THEN 'Marți'
      WHEN 4 THEN 'Miercuri'
      WHEN 5 THEN 'Joi'
      WHEN 6 THEN 'Vineri'
      WHEN 7 THEN 'Sâmbătă'
      WHEN 1 THEN 'Duminică'
    END AS zi_saptamana,
    
    -- Pasul 2: Creăm o coloană numerică simplă pentru sortare (Luni = 1, Duminică = 7)
    CASE EXTRACT(DAYOFWEEK FROM order_created_date)
      WHEN 2 THEN 1 -- Luni
      WHEN 3 THEN 2 -- Marți
      WHEN 4 THEN 3 -- Miercuri
      WHEN 5 THEN 4 -- Joi
      WHEN 6 THEN 5 -- Vineri
      WHEN 7 THEN 6 -- Sâmbătă
      WHEN 1 THEN 7 -- Duminică
    END AS ordine_sortare
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
  WHERE 
    order_status = 'finished'
)

-- Pasul 3: Facem agregarea finală pe datele deja prelucrate
SELECT 
  zi_saptamana,
  COUNT(order_reference) AS numar_curse_finalizate,
  
  -- Viteza medie calculată cu regula de maximum o zecimală
  ROUND(
    AVG(SAFE_DIVIDE(ride_distance, SAFE_DIVIDE(ride_duration, 60.0))), 
    1
  ) AS viteza_medie_kmh
FROM 
  date_pregatite
GROUP BY 
  zi_saptamana, 
  ordine_sortare
ORDER BY 
  ordine_sortare ASC;