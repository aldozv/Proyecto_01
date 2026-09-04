SELECT
  v.gerencia AS gerencia_venta,
  c.gerencia AS gerencia_cliente_vigente,
  COUNT(DISTINCT v.cliente_id) AS clientes,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202501' AND '202609'
  AND v.gerencia IN ('PE Ger P4 DA Jun Puc','PE Ger P4 Huancay Ch','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Tarapoto')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND v.gerencia <> c.gerencia
GROUP BY v.gerencia, c.gerencia
ORDER BY hl DESC
