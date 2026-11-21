-- Lima: volumen Beer+Rtds (HL) por gerencia vigente x canal (dm_cliente.unidad_negocio_revenue_volumen_meta) x anio, Ene-Oct 2023-2026.
SELECT c.gerencia, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal, SUBSTR(v.mes,1,4) AS anio, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE (v.mes BETWEEN '202301' AND '202310' OR v.mes BETWEEN '202401' AND '202410' OR v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610')
  AND c.direccion = 'PE Dir Lima'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3
LIMIT 5000
