-- Volumen (HL) Beer+Rtds por gerencia x canal, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia y canal vigentes del cliente (dm_cliente). High End se suma a DSD ON (convencion 2026-11-10).
SELECT
  cast(v.__partition_column as string) as mes,
  c.sales_region_name as gerencia,
  CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END AS canal,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), c.sales_region_name,
  CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END
ORDER BY 1, 2, 3
