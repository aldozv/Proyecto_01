-- DAS Sell Out Centro Oriente, serie mensual Ene'23-Oct'26, Beer+Rtds, por gerencia.
WITH pm AS (
  SELECT v.mes, c.gerencia, v.cliente_id, SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku b ON v.material_id = b.sku
WHERE v.mes BETWEEN '202301' AND '202610' 
  AND v.indicadores_comerciales = 1 AND c.direccion = 'PE Dir Centro Orient'
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY ALL
)
SELECT mes, gerencia, SUM(hl) AS hl, COUNT(DISTINCT CASE WHEN hl > 0 THEN cliente_id END) AS pocs
FROM pm GROUP BY GROUPING SETS ((mes, gerencia), (mes)) ORDER BY 1,2
