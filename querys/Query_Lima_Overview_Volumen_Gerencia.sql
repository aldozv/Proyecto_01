-- Overview Lima: volumen Beer+Rtds (HL) por gerencia (dm_cliente vigente) x mes, Ene-Nov 2023-2026. Corrido 2026-11-20.
SELECT c.gerencia, SUBSTR(v.mes,1,4) AS anio, SUBSTR(v.mes,5,2) AS mes_num, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE (v.mes BETWEEN '202301' AND '202311' OR v.mes BETWEEN '202401' AND '202411' OR v.mes BETWEEN '202501' AND '202511' OR v.mes BETWEEN '202601' AND '202611')
  AND c.direccion = 'PE Dir Lima'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3
ORDER BY 1,2,3
LIMIT 5000
