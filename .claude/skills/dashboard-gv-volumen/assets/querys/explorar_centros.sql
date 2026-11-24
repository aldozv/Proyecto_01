-- Paso 1 (exploratorio, correr UNA vez por lote de gerencias nuevas): que CD aparecen para
-- cada gerencia y con que volumen -- sirve para decidir el CD_LIST del dashboard por gerencia
-- (los CD marginales/de otras gerencias vecinas normalmente se excluyen, salvo el patron
-- canal DAs -- ver reglas_negocio.md). Reemplazar {{GERENCIA_IN_LIST}} con la lista de codigos
-- transaccionales entre comillas simples separados por coma, ej:
--   'PE Ger P4 Tarapoto','PE Ger P4 Iquitos'
-- Usa el mes mas reciente disponible nomas (no todo el rango) para que sea rapido.
SELECT
  v.sales_region_name as gerencia,
  c.distribution_center_name as centro,
  COUNT(*) AS filas,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) = '{{MES_HASTA}}'
  AND v.sales_region_name IN ({{GERENCIA_IN_LIST}})
  AND v.invoice_commercial_flag = 1
GROUP BY v.sales_region_name, c.distribution_center_name
ORDER BY v.sales_region_name, hl DESC
