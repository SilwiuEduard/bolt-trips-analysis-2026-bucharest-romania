EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q13_castig_curse_anulate_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS


-- Corelatia dintre Status si Bani (Reguli de Business)
-- Acest script izoleaza relatia dintre starea cursei si portofel. Ma intereseaza in special sa vad cat incasez pe anulari si daca exista anomalii (curse refuzate care sa fi generat bani din greseala sau curse terminate pe 0 lei).

-- Ce caut aici: Analizez valoarea de la castig_net_lei pentru cursele anulate (client_cancelled sau driver_cancelled). Vad exact tiparul taxelor de anulare din Bucuresti. Daca vad o cursa anulata cu un castig de ex. de 40 de lei, aceea este o anomalie de sistem.

SELECT 
  order_reference,
  order_status,
  order_price_net_earnings AS castig_net_lei,
  order_price_cancellation_fee AS taxa_anulare_bolt,
  order_price_ride_price AS pret_brut_cursa,
  order_created_date,
  order_created_time
FROM 
  `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
WHERE 
  -- Cazul 1: Curse terminate la care nu ai castigat nimic (dispute sau erori)
  (order_status = 'finished' AND COALESCE(order_price_net_earnings, 0) <= 0)
  
  -- Cazul 2: Curse refuzate/fara raspuns cu bani
  OR (order_status IN ('driver_rejected', 'driver_did_not_respond') AND order_price_net_earnings > 0)
  
  -- Cazul 3: Anulari care au generat venituri SAU care au taxa de anulare > 0
  OR (
    (order_status LIKE '%cancelled%' OR order_status = 'client_did_not_show') 
    AND (COALESCE(order_price_net_earnings, 0) > 0 OR COALESCE(order_price_cancellation_fee, 0) > 0)
  )
ORDER BY 
  order_created_date DESC, 
  order_created_time DESC;
