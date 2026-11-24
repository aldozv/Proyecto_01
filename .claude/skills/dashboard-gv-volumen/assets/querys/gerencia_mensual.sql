-- Total HL mensual SIN restriccion de CD (headline real de cada gerencia -- alimenta los KPI
-- del resumen ejecutivo, que NO se ven afectados por los filtros de Centro/Categoria del
-- dashboard). Cubre todas las gerencias del run en una sola pasada.
-- Reemplazar {{GERENCIA_IN_LIST}} (codigos entre comillas separados por coma) y
-- {{MES_DESDE}}/{{MES_HASTA}} (yyyymm).
-- CORREGIDO 2026-09-06: gerencia sale de dm_cliente (vigente), no de dm_venta -- ver CLAUDE.md
-- (caso Ucayali Beer, reasignado Huancay Ch -> DA Jun Puc en abril 2026).
SELECT
  c.sales_region_name as gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
WHERE cast(v.__partition_column as string) BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'
  AND c.sales_region_name IN ({{GERENCIA_IN_LIST}})
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
GROUP BY c.sales_region_name, CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT)
ORDER BY c.sales_region_name, anio, mes_num
