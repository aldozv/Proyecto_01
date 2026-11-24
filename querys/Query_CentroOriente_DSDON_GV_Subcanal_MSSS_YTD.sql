/* DSD ON Centro Oriente: venta Beer+Rtds YTD Ene-Oct 2023-2026 por gerencia, subcanal, MS/SS y agrupador de tipo.
   Canal, gerencia y subcanal = vigentes del cliente (dm_cliente, regla de atribucion actual); High End se suma a DSD ON.
   MS/SS y `Agrupador (Tipo 2.0)` (ej. 'SS x 24') de revenue_maestro_sku. NR = GSI + EXCISE + DSCTO. */
WITH cli AS (
  SELECT c.customer_short_code as cliente_id, REPLACE(c.sales_region_name, 'PE Ger P4 ', '') AS gv, COALESCE(c.subchannel_name, 'Sin subcanal') AS subcanal
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  WHERE c.sales_area_name = 'PE Dir Centro Orient'
    AND c.business_unit_target_volume IN ('DSD ON', 'High End')
)
SELECT cli.gv, cli.subcanal,
  COALESCE(r.ms_ss, 'Sin dato') AS ms_ss,
  COALESCE(r.`Agrupador (Tipo 2.0)`, 'Sin dato') AS agrupador,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2023%' THEN v.sales_volume_official ELSE 0 END) AS hl_23,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2024%' THEN v.sales_volume_official ELSE 0 END) AS hl_24,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2025%' THEN v.sales_volume_official ELSE 0 END) AS hl_25,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2026%' THEN v.sales_volume_official ELSE 0 END) AS hl_26,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2025%' THEN v.net_revenue_amount ELSE 0 END) AS nr_25,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2026%' THEN v.net_revenue_amount ELSE 0 END) AS nr_26,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2025%' THEN v.gross_revenue_amount ELSE 0 END) AS gsi_25,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2026%' THEN v.gross_revenue_amount ELSE 0 END) AS gsi_26,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2025%' THEN v.total_discounts_amount ELSE 0 END) AS dscto_25,
  SUM(CASE WHEN cast(v.__partition_column as string) LIKE '2026%' THEN v.total_discounts_amount ELSE 0 END) AS dscto_26
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
JOIN cli ON v.sold_to_customer_short_code = cli.cliente_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) IN ('202301','202302','202303','202304','202305','202306','202307','202308','202309','202310',
                '202401','202402','202403','202404','202405','202406','202407','202408','202409','202410',
                '202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas', 'Licores', 'Ready To Drink')
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4
