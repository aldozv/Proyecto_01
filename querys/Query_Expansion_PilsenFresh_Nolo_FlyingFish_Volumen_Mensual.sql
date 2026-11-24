-- Volumen (HL) mensual Ene'24-Oct'26 de categorias de expansion, Direccion Centro Oriente (jerarquia vigente).
-- Nolo = Corona Cero + Cusqueña Cero Trigo (definido por el usuario 13.11.26). Marca desde dm_material.  Pilsen Fresh = marcas 'Pilsen Fresh' + 'Pilsen Callao Fresh' (SKUs nuevos desde Ago'26).
SELECT cast(v.__partition_column as string) as mes,
  CASE WHEN m.brand_name IN ('Pilsen Fresh','Pilsen Callao Fresh') THEN 'Pilsen Fresh'
       WHEN m.brand_name IN ('Corona Cero','Cusqueña Cero Trigo') THEN 'Nolo'
       WHEN m.brand_name = 'Flying Fish' THEN 'Flying Fish' END AS grupo,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c ON v.sold_to_customer_short_code = c.customer_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m ON v.product_short_code = m.product_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202401' AND '202610'
  AND c.sales_area_name = 'PE Dir Centro Orient'
  AND v.invoice_commercial_flag = 1
  AND m.brand_name IN ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
GROUP BY 1, 2 ORDER BY 2, 1
