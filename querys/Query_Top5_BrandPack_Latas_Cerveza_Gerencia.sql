-- Top 5 Brand Pack de LATAS (pack LIKE '%CAN%') mas vendidas, promedio mensual de los ultimos 3
-- meses cerrados (Jun-Ago 2026), solo categoria Cervezas, a nivel Gerencia (sin CD).
-- Complemento de Query_Top5_BrandPack_Latas_Cerveza_GerenciaCD.sql.
WITH base AS (
  SELECT
    c.sales_region_name as gerencia,
    cast(v.__partition_column as string) as mes,
    v_p.brand_name as marca,
    r.pack,
    SUM(v.sales_volume_official) AS hl,
    SUM(v.billed_sales_boxes_quantity) AS caja_fisica
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
    ON v.sold_to_customer_short_code = c.customer_short_code
  INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
    ON v.product_short_code = r.sku
  WHERE cast(v.__partition_column as string) BETWEEN '202606' AND '202608'
    AND c.sales_area_name = 'PE Dir Centro Orient'
    AND v.invoice_commercial_flag = 1
    AND v_p.product_line = 'Cervezas'
    AND r.pack LIKE '%CAN%'
  GROUP BY c.sales_region_name, cast(v.__partition_column as string), v_p.brand_name, r.pack
),
agg AS (
  SELECT
    gerencia,
    marca,
    pack,
    CONCAT(marca, ' ', pack) AS brand_pack,
    SUM(hl) / 3.0 AS avg_hl_mensual,
    SUM(caja_fisica) / 3.0 AS avg_cf_mensual
  FROM base
  GROUP BY gerencia, marca, pack
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY gerencia ORDER BY avg_hl_mensual DESC) AS ranking
  FROM agg
)
SELECT gerencia, ranking, marca, pack, brand_pack, avg_hl_mensual, avg_cf_mensual
FROM ranked
WHERE ranking <= 5
ORDER BY gerencia, ranking
