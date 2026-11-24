-- DAS Sell Out (venta del distribuidor a sus POCs) Centro Oriente, YTD Ene-Oct 2023-2026, Beer+Rtds.
-- Gerencia/direccion desde dm_das_cliente (jerarquia vigente). pocs_prom = POCs compradores promedio por mes.
WITH base AS (
  SELECT SUBSTR(v.mes,1,4) AS anio, v.mes, c.gerencia, v.razon_social, v.cliente_id, v.hl, v.caja_fisica
  FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku b ON v.material_id = b.sku
WHERE v.mes BETWEEN '202301' AND '202610' AND SUBSTR(v.mes,5,2) <= '10'
  AND v.indicadores_comerciales = 1 AND c.direccion = 'PE Dir Centro Orient'
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
), pm AS (
  SELECT anio, mes, gerencia, razon_social, cliente_id, SUM(hl) AS hl, SUM(caja_fisica) AS cf FROM base GROUP BY ALL
)
SELECT anio, gerencia, razon_social, SUM(hl) AS hl, CAST(SUM(cf) AS BIGINT) AS cf,
       COUNT(DISTINCT CASE WHEN hl > 0 THEN CONCAT(mes,'|',cliente_id) END) / COUNT(DISTINCT mes) AS pocs_prom,
       COUNT(DISTINCT mes) AS n_meses
FROM pm
GROUP BY GROUPING SETS ((anio, gerencia, razon_social), (anio, gerencia), (anio))
ORDER BY anio, gerencia, razon_social
