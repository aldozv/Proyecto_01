-- San Juan 620 (marca 'San Juan' + pack '620 RB' de revenue_maestro_sku) por gerencia x CD,
-- YTD (Ene-Set, mes cerrado) 2026 vs 2025, en HL. Gerencia/CD salen de dm_cliente (regla vigente
-- CLAUDE.md 2026-09-04). Alcance: Direccion Centro Oriente (c.direccion).
SELECT
  c.sales_region_name as gerencia,
  c.distribution_center_name as centro,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202609'
  AND SUBSTR(cast(v.__partition_column as string),5,2) <= '09'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.brand_name = 'San Juan'
  AND r.pack = '620 RB'
GROUP BY c.sales_region_name, c.distribution_center_name, CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT)
ORDER BY c.sales_region_name, c.distribution_center_name, anio
