-- GV Pucallpa: base del resumen YTD (formato Resumen YTD - CO, con supervisores en lugar de gerencias).
-- Volumen mensual 2020-01 a 2026-10 por supervisor x canal x categoria. 2020 solo sirve de base para el vs LY de 2021.
-- Supervisor y canal vigentes del cliente (dm_cliente). San Mateo excluido; marca de dm_material porque dm_venta.marca es NULL hasta 2023.
SELECT CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  COALESCE(c.supervisor,'Sin supervisor') AS supervisor,
  COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal,
  CASE WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer' WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds' ELSE 'Nabs' END AS categoria,
  SUM(v.hl) AS hl
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202001' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY 1,2,3,4,5
