-- Corona Cero (marca 'Corona Cero', 355 NRB) por gerencia x CD x mes, 2025-2026 (HL).
-- Gerencia/CD de dm_cliente (regla vigente CLAUDE.md 2026-09-04). Alcance: Direccion Centro Oriente.
SELECT
  c.sales_region_name as gerencia,
  c.distribution_center_name as centro,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.brand_name = 'Corona Cero'
GROUP BY c.sales_region_name, c.distribution_center_name, CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT)
ORDER BY c.sales_region_name, c.distribution_center_name, anio, mes_num
