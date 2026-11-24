-- Lima SS deep dive Q3: compradores distintos YTD Ene-Oct por anio x gerencia x canal y estado del cliente en cada grupo
WITH b AS (
 SELECT v.sold_to_customer_short_code as cliente_id, SUBSTR(cast(v.__partition_column as string),1,4) anio, c.sales_region_name as gerencia, COALESCE(c.business_unit_target_volume,'Sin clasificar') canal,
  SUM(v.sales_volume_official) hl_tot, SUM(CASE WHEN r.ms_ss='SS' THEN v.sales_volume_official END) hl_ss,
  SUM(CASE WHEN dm.brand_name='Cristal (Peru)' AND r.pack='473 CAN' THEN v.sales_volume_official END) hl_cr,
  SUM(CASE WHEN dm.brand_name='Budweiser' AND r.pack='355 CAN' THEN v.sales_volume_official END) hl_bud
 FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code=c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm ON v.product_short_code=dm.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.product_short_code=r.sku
 WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610' AND c.sales_area_name='PE Dir Lima' AND v.invoice_commercial_flag=1 AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink') AND CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT)<=10
 GROUP BY 1,2,3,4)
SELECT anio, gerencia, canal,
 SUM(CASE WHEN hl_tot>0 THEN 1 ELSE 0 END) cli_tot, SUM(CASE WHEN hl_ss>0 THEN 1 ELSE 0 END) cli_ss,
 SUM(CASE WHEN hl_cr>0 THEN 1 ELSE 0 END) cli_cr, SUM(CASE WHEN hl_bud>0 THEN 1 ELSE 0 END) cli_bud,
 SUM(CASE WHEN hl_ss>0 AND COALESCE(hl_cr,0)<=0 THEN 1 ELSE 0 END) cli_ss_sin_cr,
 SUM(CASE WHEN hl_ss>0 AND COALESCE(hl_bud,0)<=0 THEN 1 ELSE 0 END) cli_ss_sin_bud,
 SUM(CASE WHEN hl_tot>0 AND COALESCE(hl_ss,0)<=0 THEN 1 ELSE 0 END) cli_sin_ss,
 SUM(CASE WHEN hl_ss>0 AND COALESCE(hl_cr,0)<=0 THEN hl_ss ELSE 0 END) hl_ss_de_sin_cr,
 SUM(CASE WHEN hl_ss>0 AND COALESCE(hl_bud,0)<=0 THEN hl_ss ELSE 0 END) hl_ss_de_sin_bud,
 SUM(CASE WHEN hl_tot>0 AND COALESCE(hl_ss,0)<=0 THEN hl_tot ELSE 0 END) hl_tot_de_sin_ss
FROM b GROUP BY 1,2,3 LIMIT 5000
