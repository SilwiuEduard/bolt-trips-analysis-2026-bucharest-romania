--Corelația dintre Status și Bani (Reguli de Business)
--Acest script izolează relația dintre starea cursei și portofel. Ma interesează în special să ved cât încasez pe anulări și dacă există anomalii (curse refuzate care să fi --generat bani din greșeală sau curse terminate pe 0 lei).

--💡 Ce caut aici: Analizeazez valoarea de la castig_net_lei pentru cursele anulate (client_cancelled sau driver_cancelled). Vad exact tiparul taxelor de anulare din București. Dacă ved o cursă anulată cu un câștig de ex. de 40 de lei, aceea este o anomalie de sistem.

SELECT 
  order_reference,
  order_status,
  order_price_net_earnings AS castig_net_lei,
  order_price_cancellation_fee AS taxa_anulare_bolt,
  order_price_ride_price AS pret_brut_cursa,
  order_created_date,
  order_created_time
FROM 
  `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
WHERE 
  -- Cazul 1: Curse terminate la care nu ai câștigat nimic (dispute sau erori)
  (order_status = 'finished' AND order_price_net_earnings <= 0)
  
  -- Cazul 2: Curse refuzate sau la care nu ai răspuns, dar apar bani în plus
  OR (order_status IN ('driver_rejected', 'driver_did_not_respond') AND order_price_net_earnings > 0)
  
  -- Cazul 3: Curse ANULATE (vrem să vedem exact valoarea taxelor de anulare primite)
  OR (order_status LIKE '%cancelled%' AND order_price_net_earnings > 0)
ORDER BY 
  order_status, 
  castig_net_lei DESC;