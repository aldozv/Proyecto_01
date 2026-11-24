-- DAS Sell Out Centro Oriente, YTD Ene-Oct 2023-2026, Beer+Rtds, por Agrupador (Tipo 2.0) y marca (revenue_maestro_sku).
SELECT SUBSTR(v.mes,1,4) AS anio, COALESCE(b.`Agrupador (Tipo 2.0)`,'SIN MAESTRO') AS agrupador,
       COALESCE(b.marca,'SIN MAESTRO') AS marca, SUM(v.hl) AS hl
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku b ON v.material_id = b.sku
WHERE v.mes BETWEEN '202301' AND '202610' AND SUBSTR(v.mes,5,2) <= '10'
  AND v.indicadores_comerciales = 1 AND c.direccion = 'PE Dir Centro Orient'
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY GROUPING SETS ((anio, agrupador), (anio, marca), (anio))
ORDER BY 1,2,3
