-- CD x Categoria x Cliente x Pack mensual, gerencia PE Ger P4 DA Jun Puc. Alimenta "Por Pack"
-- -- ahora con Cliente como dimension adicional (filtro global reemplaza a CD).
SELECT
  CASE WHEN v.sold_to_customer_short_code = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.sales_region_name END AS gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  c.distribution_center_name as centro,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  CASE
    WHEN c.customer_name LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.customer_name
  END AS nombre_cliente,
  COALESCE(r.pack_xxx, 'Sin mapear') AS pack_xxx,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202609'
  AND (v.sales_region_name = 'PE Ger P4 DA Jun Puc' OR v.sold_to_customer_short_code = '13836158')
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
  AND c.distribution_center_name IN ('CD Pucallpa','CD San Benedicto I (Ate)','CD Satipo','CD Huánuco','CD Huancayo','CD Huancavelica')
GROUP BY
  CASE WHEN v.sold_to_customer_short_code = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.sales_region_name END,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT), c.distribution_center_name,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  CASE
    WHEN c.customer_name LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.customer_name
  END,
  COALESCE(r.pack_xxx, 'Sin mapear')
ORDER BY gerencia, anio, mes_num, centro, categoria_grupo, nombre_cliente, pack_xxx
