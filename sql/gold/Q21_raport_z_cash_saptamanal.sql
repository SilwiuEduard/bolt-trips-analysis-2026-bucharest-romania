EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q21_raport_z_cash_saptamanal_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH calendar_saptamani AS (
  -- Generam calendarul saptamanal (axat pe ziua de Luni a fiecarei saptamani din istoric)
  -- Asta ne asigura ca si daca ai luat o saptamana intreaga de concediu, va aparea o linie cu "0.00" lei cash.
  SELECT data_raport_z_sapt
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT DATE_TRUNC(MIN(order_finished_date), WEEK(MONDAY)) FROM `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders` WHERE order_status = 'finished'),
    (SELECT DATE_TRUNC(MAX(order_finished_date), WEEK(MONDAY)) FROM `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders` WHERE order_status = 'finished'),
    INTERVAL 1 WEEK
  )) AS data_raport_z_sapt
),

curse_cash AS (
  -- Agregam sumele cash pentru fiecare saptamana
  SELECT
    DATE_TRUNC(order_finished_date, WEEK(MONDAY)) AS data_raport_z_sapt,
    COUNT(order_reference) AS numar_curse_cash,
    
    -- Formula corecta pentru cash (identica cu raportul zilnic)
    SUM(
      COALESCE(order_price_ride_price, 0)
      + COALESCE(order_price_booking_fee, 0)
      + COALESCE(order_price_toll_fee, 0)
      - COALESCE(order_price_in_app_discount, 0)
      - COALESCE(order_price_cash_discount, 0)
    ) AS cash_incasat_brut,
    
    SUM(COALESCE(order_price_in_app_discount, 0)) AS reduceri_in_app,
    SUM(COALESCE(order_price_cash_discount, 0)) AS reduceri_cash,
    SUM(COALESCE(order_price_booking_fee, 0)) AS taxa_rezervare,
    SUM(COALESCE(order_price_toll_fee, 0)) AS taxa_parcare,
    SUM(COALESCE(order_price_tip, 0)) AS bacsis
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE
    order_status = 'finished'
    AND payment_method = 'cash'
  GROUP BY
    data_raport_z_sapt
)

SELECT
  c.data_raport_z_sapt AS inceput_saptamana_luni,
  
  -- Generam eticheta exacta de interval: ex "29.09 - 04.10"
  CONCAT(
    FORMAT_DATE('%d.%m', c.data_raport_z_sapt), 
    ' - ', 
    FORMAT_DATE('%d.%m', DATE_ADD(c.data_raport_z_sapt, INTERVAL 6 DAY))
  ) AS eticheta_saptamana,
  
  COALESCE(o.numar_curse_cash, 0) AS numar_curse_cash,
  
  -- Sume formatate obligatoriu cu 2 zecimale (.00)
  FORMAT('%.2f', COALESCE(o.cash_incasat_brut, 0)) AS total_cash_pasageri_bon_fiscal,
  FORMAT('%.2f', COALESCE(o.reduceri_in_app, 0)) AS total_reduceri_in_app_bolt,
  FORMAT('%.2f', COALESCE(o.reduceri_cash, 0)) AS total_reduceri_rotunjire_cash,
  FORMAT('%.2f', COALESCE(o.taxa_rezervare, 0)) AS total_taxa_rezervare_incasata,
  FORMAT('%.2f', COALESCE(o.taxa_parcare, 0)) AS total_taxa_parcare_aeroport,
  FORMAT('%.2f', COALESCE(o.bacsis, 0)) AS bacsis_inregistrat_app

FROM 
  calendar_saptamani c
LEFT JOIN 
  curse_cash o ON c.data_raport_z_sapt = o.data_raport_z_sapt
ORDER BY
  c.data_raport_z_sapt ASC;
