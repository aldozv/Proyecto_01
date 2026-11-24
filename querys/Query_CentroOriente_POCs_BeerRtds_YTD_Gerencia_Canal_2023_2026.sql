-- POCs compradores distintos en el YTD Ene-Oct de cada anio (HL neto > 0 en el periodo), Beer+Rtds, por gerencia x canal vigente.
-- Direccion Centro Oriente, 2023-2026. Mide cobertura acumulada del periodo (no promedio mensual).
WITH base AS (
  SELECT
    SUBSTR(cast(v.__partition_column as string), 1, 4) AS anio,
    v.sold_to_customer_short_code as cliente_id,
    c.sales_region_name as gerencia,
    CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END AS canal,
    SUM(v.sales_volume_official) AS hl
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
    ON v.sold_to_customer_short_code = c.customer_short_code
  WHERE cast(v.__partition_column as string) IN ('202301','202302','202303','202304','202305','202306','202307','202308','202309','202310',
                  '202401','202402','202403','202404','202405','202406','202407','202408','202409','202410',
                  '202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                  '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND c.sales_area_name = 'PE Dir Centro Orient'
    AND v.invoice_commercial_flag = 1
    AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY SUBSTR(cast(v.__partition_column as string), 1, 4), v.sold_to_customer_short_code, c.sales_region_name,
    CASE WHEN c.business_unit_target_volume = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.business_unit_target_volume, 'Sin clasificar') END
)
SELECT anio, gerencia, canal,
  COUNT(CASE WHEN hl > 0 THEN 1 END) AS pocs,
  SUM(hl) AS hl
FROM base
GROUP BY anio, gerencia, canal
ORDER BY 1, 2, 3
