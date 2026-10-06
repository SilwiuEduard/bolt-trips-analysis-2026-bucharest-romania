EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q20_raport_z_cash_zilnic_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH calendar_zile AS (
  -- Generam absolut toate zilele calendaristice intre prima si ultima comanda
  -- Astfel, daca intr-o zi nu ai lucrat (sau n-ai avut cash), ziua va aparea totusi cu 0 lei.
  SELECT data_raport_z
  FROM UNNEST(GENERATE_DATE_ARRAY(
    (SELECT MIN(order_finished_date) FROM `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders` WHERE order_status = 'finished'),
    (SELECT MAX(order_finished_date) FROM `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders` WHERE order_status = 'finished'),
    INTERVAL 1 DAY
  )) AS data_raport_z
),

curse_cash AS (
  -- Calculam sumarul pe zile DOAR pentru cursele unde ai incasat efectiv bani in mana (cash)
  SELECT
    order_finished_date AS data_raport_z,
    COUNT(order_reference) AS numar_curse_cash,
    
    -- Formula explicata: 
    -- 1. Pret cursa (banii pe distanta/timp asteptati de Bolt)
    -- 2. PLUS: Taxa de rezervare (booking_fee) pe care pasagerul o da cash
    -- 3. PLUS: Taxa drum (OTP toll) pe care pasagerul o da cash
    -- 4. MINUS: Reducere In-App aplicata pasagerului de catre Bolt (pasagerul iti da MAI PUTIN cash, diferenta ti-o vireaza Bolt virtual pe cont, deci NU o bati pe casa)
    -- 5. MINUS: Reducere de rotunjire (daca un drum e 20.2 lei, aplicatia cere clientului 20.0 lei rotunjit, deci 0.2 se scad din cash)
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
    data_raport_z
)

SELECT
  c.data_raport_z,
  COALESCE(o.numar_curse_cash, 0) AS numar_curse_cash,
  
  -- Folosim FORMAT('%.2f') ca sa fortam afisarea vizuala ca "188.00" in loc de "188" sau "188.0" in CSV
  FORMAT('%.2f', COALESCE(o.cash_incasat_brut, 0)) AS total_cash_pasageri_bon_fiscal,
  
  -- Detaliile contabile, de asemenea cu .00 la final si COALESCE pentru zilele libere
  FORMAT('%.2f', COALESCE(o.reduceri_in_app, 0)) AS total_reduceri_in_app_bolt,
  FORMAT('%.2f', COALESCE(o.reduceri_cash, 0)) AS total_reduceri_rotunjire_cash,
  FORMAT('%.2f', COALESCE(o.taxa_rezervare, 0)) AS total_taxa_rezervare_incasata,
  FORMAT('%.2f', COALESCE(o.taxa_parcare, 0)) AS total_taxa_parcare_aeroport,
  FORMAT('%.2f', COALESCE(o.bacsis, 0)) AS bacsis_inregistrat_app

FROM 
  calendar_zile c
LEFT JOIN 
  curse_cash o ON c.data_raport_z = o.data_raport_z
ORDER BY
  c.data_raport_z ASC;
