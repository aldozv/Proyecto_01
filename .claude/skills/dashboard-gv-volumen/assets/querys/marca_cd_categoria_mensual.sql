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
-- CORREGIDO 2026-09-06: gerencia sale de dm_cliente (vigente), no de dm_venta -- ver CLAUDE.md
-- (caso Ucayali Beer, reasignado Huancay Ch -> DA Jun Puc en abril 2026).
SELECT
  c.sales_region_name as gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  c.distribution_center_name as centro,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal_meta,
  CASE
    WHEN UPPER(v_p.brand_name) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v_p.brand_name) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v_p.brand_name) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v_p.brand_name) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v_p.brand_name) LIKE 'CORONA%' OR UPPER(v_p.brand_name) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v_p.brand_name) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v_p.brand_name
  END AS marca,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'
  AND c.sales_region_name IN ({{GERENCIA_IN_LIST}})
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
  AND c.distribution_center_name IN ({{CD_IN_LIST}})
GROUP BY
  c.sales_region_name, CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT), c.distribution_center_name,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar'),
  CASE
    WHEN UPPER(v_p.brand_name) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v_p.brand_name) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v_p.brand_name) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v_p.brand_name) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v_p.brand_name) LIKE 'CORONA%' OR UPPER(v_p.brand_name) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v_p.brand_name) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v_p.brand_name
  END
ORDER BY c.sales_region_name, anio, mes_num, centro, categoria_grupo, canal_meta, marca
