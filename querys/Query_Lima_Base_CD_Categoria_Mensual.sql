-- Base Direccion Lima: gerencia x mes x CD x categoria x canal (HL), Ene-Oct 2025 y Ene-Oct 2026.
-- Alimenta el artifact "Ejecutivo Volumen - Lima" (misma estructura que el de Centro Oriente).
-- Gerencia, centro y canal salen de dm_cliente (vigente). Sin filtro de CD: Lima no tiene lista
-- curada de CDs; se toman todos los centros donde estan registrados sus clientes.
SELECT
  c.sales_region_name as gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  COALESCE(c.distribution_center_name, 'Sin centro') AS centro,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal_meta,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE (cast(v.__partition_column as string) BETWEEN '202501' AND '202510' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202610')
  AND c.sales_area_name = 'PE Dir Lima'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
GROUP BY 1,2,3,4,5,6
ORDER BY 1,2,3,4,5,6
LIMIT 20000
