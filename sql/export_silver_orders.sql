EXPORT DATA WITH CONNECTION `woven-howl-489214-k5.azure-eastus2.azure_bolttrips_conn`
OPTIONS(
  uri='azure://bolttrips.blob.core.windows.net/silver/silver_orders_*.csv',
  format='CSV',
  overwrite=true,
  header=true
) AS
SELECT * FROM `woven-howl-489214-k5.silver_bolt_trips_silviu.silver_orders`;