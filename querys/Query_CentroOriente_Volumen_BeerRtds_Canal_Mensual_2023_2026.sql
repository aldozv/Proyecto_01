-- Volumen (HL) Beer+Rtds por canal, total Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Canal = dm_cliente.unidad_negocio_revenue_volumen_meta (vigente del cliente).
-- Alcance por c.direccion (regla 2026-09-04). Beer = Cervezas+Licores; Rtds = Ready To Drink.
SELECT
  cast(v.__partition_column as string) as mes,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal,
  CASE WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds' ELSE 'Beer' END AS categoria,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), COALESCE(c.business_unit_target_volume, 'Sin clasificar'),
  CASE WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds' ELSE 'Beer' END
ORDER BY 1, 2, 3
