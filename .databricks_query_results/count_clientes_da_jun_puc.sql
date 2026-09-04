SELECT COUNT(DISTINCT v.cliente_id) AS clientes_distintos, SUM(v.hl) AS hl_total
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '202501' AND '202609'
  AND v.gerencia = 'PE Ger P4 DA Jun Puc'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
