-- Exploratoria: valores distintos de pack (revenue_maestro_sku) para Cerveza en Centro Oriente,
-- ultimos 3 meses cerrados (Jun-Ago 2026), para identificar cuales corresponden a "Latas".
SELECT
  COALESCE(r.pack, 'Sin mapear') AS pack,
  COUNT(DISTINCT v.material_id) AS skus_distintos,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '202606' AND '202608'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion = 'Cervezas'
GROUP BY COALESCE(r.pack, 'Sin mapear')
ORDER BY hl DESC
