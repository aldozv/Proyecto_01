-- Cardinalidad de marca (dm_venta.marca)
SELECT
  v.marca,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes = '202608'
  AND v.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY v.marca
ORDER BY hl DESC
