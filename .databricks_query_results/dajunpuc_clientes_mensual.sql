SELECT
  v.mes,
  COUNT(DISTINCT v.cliente_id) AS clientes_con_venta,
  SUM(v.hl) AS hl_total
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.gerencia = 'PE Ger P4 DA Jun Puc'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  AND v.mes BETWEEN '202501' AND '202609'
GROUP BY v.mes
ORDER BY v.mes
