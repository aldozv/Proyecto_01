-- Paso 1b (exploratorio, correr solo si el Paso 1 muestra un CD con volumen NO trivial en una
-- gerencia donde geograficamente no deberia estar -- ver el caso Tarapoto/CD Pucallpa en
-- reglas_negocio.md): desglosa ese CD sospechoso por canal para confirmar si es el patron DAs
-- (Distribuidores Autorizados que se abastecen del CD mas grande sin importar la gerencia de
-- facturacion) u otra cosa. Reemplazar {{GERENCIA_IN_LIST}} y {{CD_SOSPECHOSO}}.
SELECT
  v.sales_region_name as gerencia,
  c.distribution_center_name as centro,
  COALESCE(c.business_unit_target_volume, 'Sin clasificar') AS canal_meta,
  COUNT(*) AS filas,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) = '{{MES_HASTA}}'
  AND v.sales_region_name IN ({{GERENCIA_IN_LIST}})
  AND c.distribution_center_name = '{{CD_SOSPECHOSO}}'
  AND v.invoice_commercial_flag = 1
GROUP BY v.sales_region_name, c.distribution_center_name, COALESCE(c.business_unit_target_volume, 'Sin clasificar')
ORDER BY v.sales_region_name, hl DESC
