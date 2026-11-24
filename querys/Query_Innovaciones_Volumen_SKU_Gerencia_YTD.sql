-- v7 Innovaciones: volumen HL por grupo x SKU x gerencia, Ene-Oct 2025 y 2026, Centro Oriente (jerarquia vigente dm_cliente)
SELECT CASE WHEN m.brand_name IN ('Pilsen Fresh','Pilsen Callao Fresh') THEN 'Pilsen Fresh'
            WHEN m.brand_name IN ('Corona Cero','Cusqueña Cero Trigo') THEN 'Non Alc' ELSE 'Flying Fish' END AS grupo,
  m.product_name AS sku, c.sales_region_name as gerencia, substr(cast(v.__partition_column as string),1,4) AS anio, SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m ON v.product_short_code = m.product_short_code
WHERE (cast(v.__partition_column as string) BETWEEN '202501' AND '202510' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202610')
  AND c.sales_area_name = 'PE Dir Centro Orient' AND v.invoice_commercial_flag = 1
  AND m.brand_name IN ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
GROUP BY 1,2,3,4 LIMIT 2000
