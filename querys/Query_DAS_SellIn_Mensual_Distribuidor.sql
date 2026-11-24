-- Sell in a los DAS (lo que Backus factura al distribuidor), Centro Oriente, mensual Ene'23-Oct'26, Beer+Rtds.
-- DAS = dm_cliente.unidad_negocio_revenue_volumen_meta = 'DAs'; gerencia/direccion vigentes del maestro.
SELECT cast(v.__partition_column as string) as mes, c.sales_region_name as gerencia, c.customer_short_code as cliente_id, c.customer_name as nombre, SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND v.invoice_commercial_flag = 1
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND c.business_unit_target_volume = 'DAs'
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY ALL
ORDER BY 1, 2, 4
