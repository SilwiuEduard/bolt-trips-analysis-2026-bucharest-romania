WITH intervale_stari AS (
  -- Calculam cat timp a durat fiecare stare pana la urmatoarea inregistrare din loguri
  SELECT
    created_date AS data_zi,
    state,
    created_time AS timp_start,
    -- Luam timpul randului urmator din aceeasi zi pentru a afla cand s-a terminat starea curenta
    LEAD(created_time) OVER(PARTITION BY created_date ORDER BY created_time ASC) AS timp_end
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-state_logs`
),

timp_online AS (
  -- Timpul online reprezinta orice stare inafara de 'inactive'
  SELECT
    data_zi,
    SUM(TIME_DIFF(timp_end, timp_start, SECOND)) AS secunde_online_zi
  FROM 
    intervale_stari
  WHERE 
    LOWER(state) != 'inactive'
    AND timp_end IS NOT NULL
  GROUP BY 
    data_zi
),

timp_curse AS (
  -- Calculam incasarile totale si timpul alocat curselor
  SELECT
    order_created_date AS data_zi,
    -- Luam toate castigurile nete (inclusiv taxele de刻anulare primite)
    SUM(order_price_net_earnings) AS incasari_totale_zi,
    -- Timpul activ de condus convertit in secunde
    SUM(COALESCE((to_client_duration + ride_duration) * 60, 0)) AS secunde_cursa_activa_zi
  FROM 
    `woven-howl-489214-k5.bolt_driver_trips_analysis.silviu-extract_20260606_174023-orders-calculat2`
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

  -- COLOANA NOUA: Suma orelor online din acea saptamana
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