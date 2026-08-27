SELECT
  v.gerencia,
  c.centro,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes = '202608'
  AND v.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos')
  AND c.centro = 'CD Pucallpa'
  AND v.indicadores_comerciales = 1
GROUP BY v.gerencia, c.centro, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar')
ORDER BY v.gerencia, hl DESC
