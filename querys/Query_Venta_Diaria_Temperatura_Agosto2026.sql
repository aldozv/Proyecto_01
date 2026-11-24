-- Venta diaria (HL, Beer+Rtds) por gerencia de Centro Oriente, agosto 2026
-- Para cruzar a grosso modo con temperatura diaria por ciudad (analisis exploratorio,
-- no oficial). Usa c.gerencia/c.direccion de dm_cliente por regla vigente del proyecto.
SELECT
  v.invoice_date as fecha_venta,
  c.sales_region_name as gerencia,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) = '202608'
  AND v.invoice_commercial_flag = 1
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND c.sales_region_name <> 'PE Ger P4 DA Jun Puc'
  AND v_p.product_line IN ('Cervezas', 'Licores', 'Ready To Drink')
GROUP BY v.invoice_date, c.sales_region_name
ORDER BY v.invoice_date, c.sales_region_name
