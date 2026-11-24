-- Volumen MTD (1-18 Oct) 2026 vs mismo periodo 2025, Beer+Rtds, Centro Oriente.
-- Grano: gerencia x CD x canal x categoria x marca x brand_pack. Gerencia/CD/canal desde dm_cliente (regla vigente).
SELECT
  c.sales_region_name as gerencia,
  c.distribution_center_code as centro_id,
  c.distribution_center_name as centro,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal,
  CASE WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer' ELSE 'Rtds' END AS categoria,
  v_p.brand_name AS marca,
  COALESCE(m.brand_pack, 'Sin mapear') AS brand_pack,
  SUM(CASE WHEN cast(v.__partition_column as string) = '202510' THEN v.sales_volume_official ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN cast(v.__partition_column as string) = '202610' THEN v.sales_volume_official ELSE 0 END) AS hl_cy
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.product_short_code = m.material_id
WHERE cast(v.__partition_column as string) IN ('202510','202610')
  AND (v.invoice_date BETWEEN '2025-10-01' AND '2025-10-18' OR v.invoice_date BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4,5,6,7
