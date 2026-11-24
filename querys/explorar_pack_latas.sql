-- Exploratoria: valores distintos de pack (revenue_maestro_sku) para Cerveza en Centro Oriente,
-- ultimos 3 meses cerrados (Jun-Ago 2026), para identificar cuales corresponden a "Latas".
SELECT
  COALESCE(r.pack, 'Sin mapear') AS pack,
  COUNT(DISTINCT v.product_short_code) AS skus_distintos,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202606' AND '202608'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line = 'Cervezas'
GROUP BY COALESCE(r.pack, 'Sin mapear')
ORDER BY hl DESC
