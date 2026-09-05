SELECT
  `Agrupador (Sku)` AS brandpack,
  kpi_premium,
  COUNT(*) AS n_skus
FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_sku
GROUP BY `Agrupador (Sku)`, kpi_premium
ORDER BY brandpack, kpi_premium
LIMIT 200;
