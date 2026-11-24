-- Volumen (HL) Beer+Rtds por gerencia x CD, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia y CD vigentes del cliente (dm_cliente.gerencia / centro_id / centro).
SELECT
  cast(v.__partition_column as string) as mes,
  c.sales_region_name as gerencia,
  COALESCE(c.distribution_center_code, 'Sin CD') AS centro_id,
  COALESCE(c.distribution_center_name, 'Sin CD') AS centro,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), c.sales_region_name, COALESCE(c.distribution_center_code, 'Sin CD'), COALESCE(c.distribution_center_name, 'Sin CD')
ORDER BY 1, 2, 3
