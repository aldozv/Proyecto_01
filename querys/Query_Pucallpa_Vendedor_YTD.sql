-- GV Pucallpa: Beer+Rtds YTD Ene-Oct 2025 vs 2026 por CD x supervisor x vendedor x canal, con POCs activos.
WITH cy AS (
  SELECT CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio, v.sold_to_customer_short_code as cliente_id, c.distribution_center_name as centro, COALESCE(c.sales_subregion_name,'Sin supervisor') AS supervisor,
    COALESCE(c.bdr_name,'Sin vendedor') AS vendedor, COALESCE(c.business_unit_target_volume,'Sin clasificar') AS canal, SUM(v.sales_volume_official) AS hl
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
  WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202610' AND c.sales_region_name = 'PE Ger P4 Pucall Hco' AND v.invoice_commercial_flag = 1 AND CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) <= 10 AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY 1,2,3,4,5,6
)
SELECT centro, supervisor, vendedor, canal,
  SUM(CASE WHEN anio=2025 THEN hl ELSE 0 END) AS hl_25, SUM(CASE WHEN anio=2026 THEN hl ELSE 0 END) AS hl_26,
  COUNT(DISTINCT CASE WHEN anio=2025 AND hl>0 THEN cliente_id END) AS pocs_25, COUNT(DISTINCT CASE WHEN anio=2026 AND hl>0 THEN cliente_id END) AS pocs_26
FROM cy GROUP BY 1,2,3,4
