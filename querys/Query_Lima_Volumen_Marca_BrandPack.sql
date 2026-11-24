-- Lima: volumen Beer+Rtds (HL) por gerencia vigente (dm_cliente) x brand x brand_pack x anio, Ene-Oct 2023-2026.
-- Marca y brand pack desde brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material (mismo maestro que Brand
-- Distribution, mas limpio que dm_venta.marca que trae variantes de mayusculas y sabores).
SELECT c.sales_region_name as gerencia, COALESCE(m.brand,'Sin mapear') AS brand, COALESCE(m.brand_pack,'Sin mapear') AS brand_pack,
       SUBSTR(cast(v.__partition_column as string),1,4) AS anio, SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m ON v.product_short_code = m.material_id
WHERE (cast(v.__partition_column as string) BETWEEN '202301' AND '202310' OR cast(v.__partition_column as string) BETWEEN '202401' AND '202410' OR cast(v.__partition_column as string) BETWEEN '202501' AND '202510' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202610')
  AND c.sales_area_name = 'PE Dir Lima'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
