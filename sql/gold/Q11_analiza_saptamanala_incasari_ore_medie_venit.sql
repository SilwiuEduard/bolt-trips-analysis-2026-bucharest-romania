EXPORT DATA WITH CONNECTION `azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/gold/gold_bolt_trips_silviu_Q11_analiza_saptamanala_incasari_ore_medie_venit_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS

WITH timp_online AS (
  -- Timpul online reprezinta orice stare inafara de 'inactive'
  -- Refolosim coloana gata calculata (secunde_in_stare) din Silver pentru a nu mai scrie noi logica de tip LEAD/TIME_DIFF
  SELECT
    created_date AS data_zi,
    SUM(secunde_in_stare) AS secunde_online_zi
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_state_logs`
  WHERE 
    LOWER(state) != 'inactive'
    AND secunde_in_stare IS NOT NULL
  GROUP BY 
    created_date
),

timp_curse AS (
  -- Calculam incasarile totale si timpul alocat curselor
  SELECT
    order_created_date AS data_zi,
    -- Luam toate castigurile nete (inclusiv taxele de anulare primite)
    SUM(order_price_net_earnings) AS incasari_totale_zi,
    -- Timpul activ de condus (preluare + cursa) preluat direct in secunde
    SUM(COALESCE(total_trip_duration_seconds, 0)) AS secunde_cursa_activa_zi
  FROM 
    `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`
  WHERE 
    order_price_net_earnings > 0
  GROUP BY 
    data_zi
)

SELECT
  -- Grupare pe inceput de saptamana (Luni) pentru Axa X din Power BI
  DATE_TRUNC(o.data_zi, WEEK(MONDAY)) AS inceput_saptamana,
  CONCAT('Sapt. ', FORMAT_DATE('%d-%b', DATE_TRUNC(o.data_zi, WEEK(MONDAY)))) AS eticheta_saptamana,

  -- BARE: Incasari totale saptamanale
  ROUND(SUM(o.incasari_totale_zi), 1) AS incasari_totale_lei,

  -- Suma orelor online din acea saptamana
  ROUND(SUM(l.secunde_online_zi) / 3600.0, 1) AS ore_online_totale_saptamana,

  -- LINIA 1: Castig net mediu pe ora (Incasari / Ore Online)
  ROUND(
    SUM(o.incasari_totale_zi) / NULLIF((SUM(l.secunde_online_zi) / 3600.0), 0), 
    1
  ) AS medie_lei_per_ora,

  -- LINIA 2: Procentul de utilizare mediu al timpului
  ROUND(
    (SUM(o.secunde_cursa_activa_zi) / NULLIF(SUM(l.secunde_online_zi), 0)) * 100, 
    1
  ) AS medie_procent_utilizare

FROM 
  timp_curse o
INNER JOIN 
  timp_online l ON o.data_zi = l.data_zi
GROUP BY 
  inceput_saptamana,
  eticheta_saptamana
ORDER BY 
  inceput_saptamana ASC;
