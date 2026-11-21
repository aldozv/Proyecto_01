-- v7 Innovaciones: volumen HL por grupo x SKU x gerencia, Ene-Oct 2025 y 2026, Centro Oriente (jerarquia vigente dm_cliente)
SELECT CASE WHEN m.marca IN ('Pilsen Fresh','Pilsen Callao Fresh') THEN 'Pilsen Fresh'
            WHEN m.marca IN ('Corona Cero','Cusqueña Cero Trigo') THEN 'Non Alc' ELSE 'Flying Fish' END AS grupo,
  m.nombre AS sku, c.gerencia, substr(v.mes,1,4) AS anio, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
WHERE (v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610')
  AND c.direccion = 'PE Dir Centro Orient' AND v.indicadores_comerciales = 1
  AND m.marca IN ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
GROUP BY 1,2,3,4 LIMIT 2000
