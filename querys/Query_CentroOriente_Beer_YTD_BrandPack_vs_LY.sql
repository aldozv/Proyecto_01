-- YTD (Ene-Set) 2026 vs 2025, solo categoria Beer (Cervezas + Licores), por brand_pack, HL.
-- Direccion Centro Oriente via dm_cliente (regla vigente: atribucion por cliente actual).
SELECT
  COALESCE(m.brand_pack, 'Sin mapear') AS brand_pack,
  SUM(CASE WHEN cast(v.__partition_column as string) BETWEEN '202501' AND '202509' THEN v.sales_volume_official ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN cast(v.__partition_column as string) BETWEEN '202601' AND '202609' THEN v.sales_volume_official ELSE 0 END) AS hl_cy
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.product_short_code = m.material_id
WHERE (cast(v.__partition_column as string) BETWEEN '202501' AND '202509' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202609')
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores')
GROUP BY COALESCE(m.brand_pack, 'Sin mapear')
ORDER BY SUM(CASE WHEN cast(v.__partition_column as string) BETWEEN '202601' AND '202609' THEN v.sales_volume_official ELSE 0 END) DESC
