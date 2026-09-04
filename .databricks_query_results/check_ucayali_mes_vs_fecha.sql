SELECT
  v.mes,
  MIN(v.fecha_venta) AS fecha_min,
  MAX(v.fecha_venta) AS fecha_max,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.cliente_id = '13836158'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
GROUP BY v.mes
ORDER BY v.mes
