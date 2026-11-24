-- DAS Sell Out Centro Oriente, YTD Ene-Oct 2023-2026, Beer+Rtds, por canal/subcanal del POC.
WITH pm AS (
  SELECT SUBSTR(v.mes,1,4) AS anio, v.mes, c.gerencia, v.canal_cliente, v.subcanal_cliente, v.cliente_id, SUM(v.hl) AS hl
  FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku b ON v.material_id = b.sku
WHERE v.mes BETWEEN '202301' AND '202610' AND SUBSTR(v.mes,5,2) <= '10'
  AND v.indicadores_comerciales = 1 AND c.direccion = 'PE Dir Centro Orient'
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY ALL
)
SELECT anio, gerencia, canal_cliente, subcanal_cliente, SUM(hl) AS hl,
       COUNT(DISTINCT CASE WHEN hl > 0 THEN CONCAT(mes,'|',cliente_id) END) / COUNT(DISTINCT mes) AS pocs_prom
FROM pm
GROUP BY GROUPING SETS ((anio, canal_cliente, subcanal_cliente), (anio, canal_cliente), (anio, gerencia, canal_cliente))
ORDER BY 1,2,3,4
