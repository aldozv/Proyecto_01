-- GV Pucallpa: volumen y NR YTD Ene-Oct por anio x CD x canal x categoria x marca x pack.
-- Marca de dm_material: dm_venta.marca viene NULL en 2021-2023.
SELECT CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, c.centro, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal, CASE WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer' WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds' WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs' END AS categoria,
  CASE WHEN UPPER(m.marca) LIKE 'MIKES%' THEN 'Mikes' WHEN UPPER(m.marca) = 'GOLDEN' THEN 'Golden' WHEN UPPER(m.marca) = 'CRISTAL (PERU)' THEN 'Cristal' WHEN UPPER(m.marca) LIKE 'CUSQUEÑA%' THEN 'Cusqueña' WHEN UPPER(m.marca) LIKE 'CORONA%' OR UPPER(m.marca) LIKE 'CORONITA%' THEN 'Corona' WHEN UPPER(m.marca) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao' ELSE m.marca END AS marca, COALESCE(r.pack_xxx,'Sin mapear') AS pack_xxx, COALESCE(r.pack,'Sin mapear') AS formato,
  SUM(v.hl) AS hl, SUM(v.nr) AS nr
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id = r.sku
WHERE v.mes BETWEEN '202101' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1 AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas') AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY 1,2,3,4,5,6,7
