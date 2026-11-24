-- Evolucion volumen (HL) Beer+Rtds, total Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Beer = Cervezas + Licores; Rtds = Ready To Drink. Nabs fuera (regla CLAUDE.md).
-- Alcance por jerarquia vigente: c.direccion de dm_cliente (regla 2026-09-04).
SELECT
  cast(v.__partition_column as string) as mes,
  v_p.product_line as estratificacion,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), v_p.product_line
ORDER BY cast(v.__partition_column as string), v_p.product_line
