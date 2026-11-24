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
  COALESCE(r.pack, 'Sin mapear') AS formato,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202610'
  AND c.sales_region_name IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
  AND c.distribution_center_name IN ('CD Pucallpa','CD Huánuco','CD Tingo María','CD Tarapoto','CD Yurimaguas','CD Moyobamba','CD Iquitos','CD Huancayo','CD Chanchamayo','CD Satipo','CD Huancavelica','CD San Benedicto I (Ate)','CD Motupe','CD Chiclayo')
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
  END,
  COALESCE(r.pack, 'Sin mapear')
ORDER BY c.sales_region_name, anio, mes_num, centro, categoria_grupo, canal_meta, marca, formato
