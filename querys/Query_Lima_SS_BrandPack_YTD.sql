-- Lima SS deep dive Q2: YTD Ene-Oct por anio x gerencia x marca x pack, solo Single Serve
SELECT SUBSTR(cast(v.__partition_column as string),1,4) anio, c.sales_region_name as gerencia, dm.brand_name as marca, r.pack, SUM(v.sales_volume_official) hl, SUM(v.net_revenue_amount) nr, SUM(v.gross_revenue_amount) gsi, SUM(v.total_discounts_amount) dscto
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code=c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm ON v.product_short_code=dm.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.product_short_code=r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610' AND c.sales_area_name='PE Dir Lima' AND v.invoice_commercial_flag=1 AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink') AND CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT)<=10 AND r.ms_ss='SS'
GROUP BY 1,2,3,4
LIMIT 20000
