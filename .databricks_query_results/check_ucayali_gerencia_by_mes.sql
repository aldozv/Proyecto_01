SELECT
  v.mes,
  v.gerencia,
  v.direccion,
  v.gerencia_historia,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.cliente_id = '13836158'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND v.mes BETWEEN '202501' AND '202609'
GROUP BY v.mes, v.gerencia, v.direccion, v.gerencia_historia
ORDER BY v.mes
