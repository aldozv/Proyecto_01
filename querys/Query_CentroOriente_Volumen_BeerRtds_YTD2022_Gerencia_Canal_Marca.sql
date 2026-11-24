-- Volumen (HL) Beer+Rtds YTD Ene-Oct 2022 por gerencia x canal x marca, Direccion Centro Oriente.
-- Base 2022 para los puentes YTD 22 -> 26. Gerencia y canal vigentes (dm_cliente), High End dentro de DSD ON,
-- marca desde dm_material (dm_venta.marca viene nulo en historico).
SELECT
  c.sales_region_name as gerencia,
  CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END AS canal,
  COALESCE(m.brand_name, 'Sin marca') AS marca,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m
  ON v.product_short_code = m.product_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202201' AND '202210'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY c.sales_region_name,
  CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END,
  COALESCE(m.brand_name, 'Sin marca')
ORDER BY 1, 2, 3
