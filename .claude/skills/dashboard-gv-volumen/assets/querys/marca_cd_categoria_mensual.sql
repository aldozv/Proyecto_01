-- CD x Categoria x Canal x Marca mensual, todas las gerencias del run. Alimenta "Por Marca" y
-- el filtro global de Canal.
-- Mismos placeholders que base_cd_categoria_mensual.sql.
-- Normalizacion de marca (maestro trae duplicados/variantes de escritura, confirmado con el
-- usuario 2026-08-31 en Centro Oriente):
--   "golden"/"Golden"                              -> "Golden"
--   Mikes H Fresa/Lemon/Maracuya/Arandano/Apple/Mango Hot (cualquier capitalizacion) -> "Mikes"
--   "Cristal (Peru)"                                -> "Cristal" (OJO: "Cristalina" es otra marca, no tocar)
--   Cualquier "Cusqueña ..." (Trigo/Malta/Negra/Quinua/Doble Malta/Red Lager/Cero Trigo/etc.) -> "Cusqueña"
--   Cualquier "Corona ..." o "Coronita ..." (Extra/Cero/Tropical)                -> "Corona"
--   "Pilsen Callao Fresh"                           -> "Pilsen Callao" (OJO: "Pilsen Fresh" y "Pilsen Trujillo" son otras marcas, no tocar)
-- Si al correr esto para otra direccion aparecen mas duplicados de este tipo, confirmar con el
-- usuario antes de sumarlos aca (ver reglas_negocio.md) -- no asumir que aplica igual en todos
-- lados, y cuidado con nombres que EMPIEZAN igual pero son marcas distintas (Cristal/Cristalina,
-- Pilsen Callao/Pilsen Fresh/Pilsen Trujillo).
SELECT
  v.gerencia,
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
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'
  AND v.gerencia IN ({{GERENCIA_IN_LIST}})
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ({{CD_IN_LIST}})
GROUP BY
  v.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
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
  END
ORDER BY v.gerencia, anio, mes_num, centro, categoria_grupo, canal_meta, marca
