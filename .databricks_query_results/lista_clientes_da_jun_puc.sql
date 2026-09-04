SELECT
  v.cliente_id,
  c.nombre,
  c.centro,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  SUM(v.hl) AS hl_total
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202501' AND '202609'
  AND v.gerencia = 'PE Ger P4 DA Jun Puc'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY v.cliente_id, c.nombre, c.centro, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar')
ORDER BY hl_total DESC
LIMIT 50
