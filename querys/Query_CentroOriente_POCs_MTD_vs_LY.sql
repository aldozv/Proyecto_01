-- POCs compradores (Beer+Rtds) y HL MTD 1-18 Oct 2026 vs 2025, por gerencia x CD x canal.
-- Permite separar el gap en "menos clientes comprando" vs "menos volumen por cliente".
SELECT
  c.sales_region_name as gerencia, c.distribution_center_code as centro_id, COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal,
  SUBSTR(cast(v.__partition_column as string),1,4) AS anio,
  COUNT(DISTINCT CASE WHEN v.sales_volume_official > 0 THEN v.sold_to_customer_short_code END) AS pocs,
  COUNT(DISTINCT CASE WHEN v.sales_volume_official > 0 THEN CONCAT(v.sold_to_customer_short_code, '|', CAST(v.invoice_date AS STRING)) END) AS visitas,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) IN ('202510','202610')
  AND (v.invoice_date BETWEEN '2025-10-01' AND '2025-10-18' OR v.invoice_date BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
