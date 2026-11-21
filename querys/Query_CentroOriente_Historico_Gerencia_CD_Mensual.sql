-- Historico mensual de volumen (HL) por gerencia x CD x categoria, desde 2020-01 hasta el mes en curso.
-- Alcance: Direccion Centro Oriente (c.direccion). Gerencia y CD de dm_cliente (foto vigente, regla
-- CLAUDE.md 2026-09-04): atribuye TODO el historico de un cliente a su gerencia/CD ACTUAL.
-- Categorias: Beer = Cervezas+Licores, Rtds = Ready To Drink, Nabs = Gaseosas+Agua+Maltas (sin San Mateo).
-- San Mateo se filtra con dm_material.marca: dm_venta.marca es NULL en todo 2020-2023 y con ella el filtro elimina toda el Agua.
SELECT
  c.gerencia,
  c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
  ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202001' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY c.gerencia, c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY c.gerencia, c.centro, categoria_grupo, anio, mes_num
