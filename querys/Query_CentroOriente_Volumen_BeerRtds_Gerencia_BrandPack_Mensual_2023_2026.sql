-- Volumen (HL) Beer+Rtds por gerencia x marca x pack, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Igual que Query_CentroOriente_Volumen_BeerRtds_BrandPack_Mensual_2023_2026.sql + c.gerencia (gerencia vigente del cliente).
-- Marca de dm_material (dm_venta.marca es NULL antes de 2024); pack de revenue_maestro_sku. Agrupacion de marcas en el deck (BITACORA).
SELECT
  cast(v.__partition_column as string) as mes,
  c.sales_region_name as gerencia,
  COALESCE(m.brand_name, 'Sin marca') AS marca,
  COALESCE(r.pack, 'Sin mapear') AS pack,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m
  ON v.product_short_code = m.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
GROUP BY cast(v.__partition_column as string), c.sales_region_name, COALESCE(m.brand_name, 'Sin marca'), COALESCE(r.pack, 'Sin mapear')
ORDER BY 1, 2, 3, 4
LIMIT 20000
