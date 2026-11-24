-- Gerencia x Categoria x Pack x Pack XXX mensual (Centro Oriente, Ene-Set 2025 vs 2026). Alimenta los
-- building blocks "Por Pack XXX" y "Por Pack" del reporte ejecutivo de volumen.
-- pack = formato exacto (ej. "355 CAN", "620 RB"); pack_xxx = agrupacion gruesa (ej. "CAN XXX", "RB 6XX").
-- Fuente revenue_maestro_sku (carga manual): validar que "Sin mapear" no traiga volumen relevante.
-- Gerencia desde dm_cliente (regla vigente 2026-09-04), mismos filtros/CDs que Query_CentroOriente_Canal_CD_Categoria_Mensual.sql.
SELECT
  c.sales_region_name as gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(r.pack, 'Sin mapear') AS pack,
  COALESCE(r.pack_xxx, 'Sin mapear') AS pack_xxx,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.product_short_code = r.sku
WHERE (cast(v.__partition_column as string) BETWEEN '202501' AND '202509' OR cast(v.__partition_column as string) BETWEEN '202601' AND '202609')
  AND c.sales_region_name IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
  AND c.distribution_center_name IN ('CD Pucallpa','CD Huánuco','CD Tingo María','CD Tarapoto','CD Yurimaguas','CD Moyobamba','CD Iquitos','CD Huancayo','CD Chanchamayo','CD Satipo','CD Huancavelica','CD San Benedicto I (Ate)','CD Motupe','CD Chiclayo')
GROUP BY
  c.sales_region_name, CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT),
  CASE
    WHEN v_p.product_line IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v_p.product_line = 'Ready To Drink' THEN 'Rtds'
    WHEN v_p.product_line IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(r.pack, 'Sin mapear'), COALESCE(r.pack_xxx, 'Sin mapear')
ORDER BY c.sales_region_name, anio, mes_num, categoria_grupo, pack
