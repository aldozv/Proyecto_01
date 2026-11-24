-- Historico mensual de volumen (HL) por gerencia x canal x categoria, 2020-01 a 2026-10.
-- Canal = dm_cliente.unidad_negocio_revenue_volumen_meta (foto vigente del cliente; High End se pliega
-- en DSD ON en el analisis). Gerencia de dm_cliente (regla vigente CLAUDE.md 2026-09-04).
-- San Mateo se filtra con dm_material.marca: dm_venta.marca es NULL en todo 2020-2023 y con ella el filtro elimina toda el Agua.
SELECT
  c.gerencia,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
  ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202001' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY c.gerencia, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar'),
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY c.gerencia, canal_meta, categoria_grupo, anio, mes_num
