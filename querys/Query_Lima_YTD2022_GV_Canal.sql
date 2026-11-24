-- Lima: volumen Beer+Rtds (HL) YTD Ene-Oct 2022 por gerencia vigente x canal vigente (dm_cliente). Base de las cascadas 22->26.
SELECT c.sales_region_name as gerencia, COALESCE(c.business_unit_target_volume,'Sin clasificar') AS canal, SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202201' AND '202210'
  AND c.sales_area_name = 'PE Dir Lima'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2
LIMIT 1000
