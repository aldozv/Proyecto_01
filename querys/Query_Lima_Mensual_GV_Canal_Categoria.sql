-- Lima: volumen Beer+Rtds (HL) mensual Ene'23-Oct'26 por gerencia vigente x canal vigente (dm_cliente) x categoria.
-- Alimenta presentacion_volumen_lima_2023_2026.html y Datos_Volumen_Lima_2023_2026.xlsx.
SELECT c.sales_region_name as gerencia,
       COALESCE(c.business_unit_target_volume,'Sin clasificar') AS canal,
       CASE WHEN v_p.product_line = 'Ready To Drink' THEN 'RTD' ELSE v_p.product_line END AS categoria,
       cast(v.__partition_column as string) as mes, SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Lima'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
