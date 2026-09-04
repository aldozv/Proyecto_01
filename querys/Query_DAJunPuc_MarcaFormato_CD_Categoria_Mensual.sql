-- CD x Categoria x Marca x Formato mensual, gerencia PE Ger P4 DA Jun Puc. Alimenta "Por Marca x Formato".
-- EXCEPCION cliente_id 13836158 (Ucayali Beer S.A.C.): reasignado 100% a DA Jun Puc a pedido
-- del usuario 2026-09-03 (ver reglas_negocio.md) -- v.gerencia real es Huancay Ch hasta 202603.
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
    WHEN UPPER(v.marca) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v.marca) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v.marca) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v.marca) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v.marca) LIKE 'CORONA%' OR UPPER(v.marca) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v.marca) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v.marca
  END,
  COALESCE(r.pack, 'Sin mapear')
ORDER BY gerencia, anio, mes_num, centro, categoria_grupo, marca, formato
