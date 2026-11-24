-- Clientes de canales concentrados (DAs, Mayoristas, Eventos, KKAA, High End) MTD 1-18 Oct 2026 vs 2025, Beer+Rtds.
-- Identifica que clientes puntuales explican el gap en estos canales.
SELECT c.sales_region_name as gerencia, c.distribution_center_code as centro_id, COALESCE(c.business_unit_target_volume,'Sin clasificar') AS canal,
  v.sold_to_customer_short_code as cliente_id, MAX(c.customer_name) AS nombre,
  SUM(CASE WHEN cast(v.__partition_column as string)='202510' THEN v.sales_volume_official ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN cast(v.__partition_column as string)='202610' THEN v.sales_volume_official ELSE 0 END) AS hl_cy
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) IN ('202510','202610')
  AND (v.invoice_date BETWEEN '2025-10-01' AND '2025-10-18' OR v.invoice_date BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.sales_area_name = 'PE Dir Centro Orient' AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  AND c.business_unit_target_volume NOT IN ('DSD OFF','DSD ON')
GROUP BY 1,2,3,4
HAVING ABS(SUM(CASE WHEN cast(v.__partition_column as string)='202610' THEN v.sales_volume_official ELSE 0 END) - SUM(CASE WHEN cast(v.__partition_column as string)='202510' THEN v.sales_volume_official ELSE 0 END)) >= 100
ORDER BY ABS(SUM(CASE WHEN cast(v.__partition_column as string)='202610' THEN v.sales_volume_official ELSE 0 END) - SUM(CASE WHEN cast(v.__partition_column as string)='202510' THEN v.sales_volume_official ELSE 0 END)) DESC
LIMIT 60
