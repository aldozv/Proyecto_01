-- Direccion Lima: volumen Beer+Rtds (HL) por gerencia vigente x anio x marca x brand_pack, Ene-Oct 2023-2026.
-- Marca normalizada igual que Query_CentroOriente_Marca_CD_Categoria_Mensual.sql. brand_pack desde
-- pe_portfolio_material (join por material_id). Alimenta las slides de marcas/brandpacks de Informe_Overview_Lima.html.
SELECT
  c.sales_region_name as gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CASE
    WHEN UPPER(v_p.brand_name) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v_p.brand_name) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v_p.brand_name) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v_p.brand_name) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v_p.brand_name) LIKE 'CORONA%' OR UPPER(v_p.brand_name) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v_p.brand_name) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v_p.brand_name
  END AS marca,
  COALESCE(m.brand_pack, 'Sin brand_pack') AS brand_pack,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.product_short_code = m.material_id
WHERE (cast(v.__partition_column as string) BETWEEN '202301' AND '202310' OR cast(v.__partition_column as string) BETWEEN '202401' AND '202410'
       OR cast(v.__partition_column as string) BETWEEN '202501' AND '202510' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202610')
  AND c.sales_area_name = 'PE Dir Lima'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
