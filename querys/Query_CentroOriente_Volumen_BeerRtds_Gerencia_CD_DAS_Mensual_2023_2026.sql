-- Volumen (HL) Beer+Rtds por gerencia x CD x flag DAS, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia, CD y canal vigentes del cliente (dm_cliente). DAS = unidad_negocio_revenue_volumen_meta = 'DAs'.
-- Uso: en GV Iquitos y Tarapoto se reporta "DAS - CD X" separado de "CD X" (resto de canales).
SELECT
  cast(v.__partition_column as string) as mes,
  c.sales_region_name as gerencia,
  COALESCE(c.distribution_center_code, 'Sin CD') AS centro_id,
  COALESCE(c.distribution_center_name, 'Sin CD') AS centro,
  CASE WHEN c.business_unit_target_volume = 'DAs' THEN 'DAS' ELSE 'Directo' END AS tipo,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), c.sales_region_name, COALESCE(c.distribution_center_code, 'Sin CD'), COALESCE(c.distribution_center_name, 'Sin CD'),
  CASE WHEN c.business_unit_target_volume = 'DAs' THEN 'DAS' ELSE 'Directo' END
ORDER BY 1, 2, 3
