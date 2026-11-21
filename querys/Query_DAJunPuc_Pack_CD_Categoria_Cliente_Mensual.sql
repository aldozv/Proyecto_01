-- CD x Categoria x Cliente x Pack mensual, gerencia PE Ger P4 DA Jun Puc. Alimenta "Por Pack"
-- -- ahora con Cliente como dimension adicional (filtro global reemplaza a CD).
SELECT
  CASE WHEN v.cliente_id = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.gerencia END AS gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  CASE
    WHEN c.nombre LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.nombre
  END AS nombre_cliente,
  COALESCE(r.pack_xxx, 'Sin mapear') AS pack_xxx,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '202501' AND '202609'
  AND (v.gerencia = 'PE Ger P4 DA Jun Puc' OR v.cliente_id = '13836158')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ('CD Pucallpa','CD San Benedicto I (Ate)','CD Satipo','CD Huánuco','CD Huancayo','CD Huancavelica')
GROUP BY
  CASE WHEN v.cliente_id = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.gerencia END,
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  CASE
    WHEN c.nombre LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.nombre
  END,
  COALESCE(r.pack_xxx, 'Sin mapear')
ORDER BY gerencia, anio, mes_num, centro, categoria_grupo, nombre_cliente, pack_xxx
