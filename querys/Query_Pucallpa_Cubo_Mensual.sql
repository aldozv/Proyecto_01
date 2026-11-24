-- GV Pucallpa: volumen y valor mensual 2021-01 a 2026-10 por CD x supervisor x canal x categoria.
-- Gerencia, CD, supervisor y canal salen de dm_cliente (foto vigente, regla CLAUDE.md 2026-09-04).
SELECT CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro, COALESCE(c.supervisor,'Sin supervisor') AS supervisor, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal,
  CASE WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer' WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds' WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs' END AS categoria,
  SUM(v.hl) AS hl, SUM(v.nr) AS nr, SUM(v.gsi) AS gsi, SUM(v.descuento) AS descuento, SUM(v.excise) AS excise
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202101' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas') AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY 1,2,3,4,5,6
