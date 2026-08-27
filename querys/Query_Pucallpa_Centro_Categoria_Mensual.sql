-- HL y NR mensual por CD x grupo de categoria, gerencia Pucallpa, 2023-2026
-- (2023 solo como base LY de 2024, no se muestra como periodo propio en el dashboard)
-- Acotado a los 3 CD del alcance del dashboard (CD Pucallpa, CD Huanuco, CD Tingo Maria)
SELECT
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro AS centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  SUM(v.hl) AS hl,
  SUM(v.nr) AS nr
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202608'
  AND v.gerencia = 'PE Ger P4 Pucall Hco'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ('CD Pucallpa','CD Huánuco','CD Tingo María')
GROUP BY
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END
ORDER BY anio, mes_num, centro, categoria_grupo
