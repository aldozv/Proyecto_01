-- CD x Categoria x Canal x Marca x Formato (pack, via revenue_maestro_sku) mensual, todas las
-- gerencias del run. Alimenta "Por Marca x Formato" y el filtro global de Canal (cruce de las
-- dos dimensiones marca+formato). Mismas reglas de
-- normalizacion de marca que marca_cd_categoria_mensual.sql (confirmar si aplican para otra
-- direccion antes de asumirlas -- ver reglas_negocio.md) y mismo join/validacion de cobertura
-- que formato_cd_categoria_mensual.sql. Mismos placeholders que base_cd_categoria_mensual.sql.
-- OJO volumetria: esta query tiene 2 dims de detalle (marca + formato) en vez de 1, dimensiona
-- con un COUNT(*) antes de correrla para un alcance nuevo (puede ser bastante mas grande que las
-- otras 5 queries).
-- CORREGIDO 2026-09-06: gerencia sale de dm_cliente (vigente), no de dm_venta -- ver CLAUDE.md
-- (caso Ucayali Beer, reasignado Huancay Ch -> DA Jun Puc en abril 2026).
SELECT
  c.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  CASE
    WHEN UPPER(v.marca) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v.marca) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v.marca) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v.marca) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v.marca) LIKE 'CORONA%' OR UPPER(v.marca) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v.marca) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v.marca
  END AS marca,
  COALESCE(r.pack, 'Sin mapear') AS formato,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '202501' AND '202609'
  AND c.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ('CD Pucallpa','CD Huánuco','CD Tingo María','CD Tarapoto','CD Yurimaguas','CD Moyobamba','CD Iquitos','CD Huancayo','CD Chanchamayo','CD Satipo','CD Huancavelica','CD San Benedicto I (Ate)','CD Motupe','CD Chiclayo')
GROUP BY
  c.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar'),
  CASE
    WHEN UPPER(v.marca) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v.marca) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v.marca) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v.marca) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v.marca) LIKE 'CORONA%' OR UPPER(v.marca) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v.marca) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v.marca
  END,
  COALESCE(r.pack, 'Sin mapear')
ORDER BY c.gerencia, anio, mes_num, centro, categoria_grupo, canal_meta, marca, formato
