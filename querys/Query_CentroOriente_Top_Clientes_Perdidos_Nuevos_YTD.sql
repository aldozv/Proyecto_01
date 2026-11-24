/* Top 5 clientes por GV que dejaron de comprar (alta antes de 2025, compraron Ene-Oct 2025 y no Ene-Oct 2026) y top 5
   clientes nuevos (alta 2025-2026) que mas compran en Ene-Oct 2026. Beer+Rtds, cartera de Centro Oriente (dm_cliente vigente).
   Sirve para detectar recodificaciones (mismo grupo con codigo/RUC nuevo, ej. Bonanza en Iquitos) y rotacion de cuentas grandes. */
WITH cli AS (
  SELECT c.customer_short_code as cliente_id, REPLACE(c.sales_region_name, 'PE Ger P4 ', '') AS gv, c.customer_name as nombre, c.customer_status as estado, YEAR(c.customer_updated_at) AS anio_alta,
    c.business_unit_target_volume AS canal, c.subchannel_name as subcanal, c.distribution_center_code as centro_id
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  WHERE c.sales_area_name = 'PE Dir Centro Orient' AND LEN(c.customer_short_code) = 8
    AND c.business_unit NOT LIKE 'DAs Sellout' AND c.business_unit NOT LIKE 'Consumidor'

),
v AS (
  SELECT dv.sold_to_customer_short_code as cliente_id,
    SUM(CASE WHEN cast(dv.__partition_column as string) LIKE '2025%' THEN dv.sales_volume_official ELSE 0 END) AS hl_25,
    SUM(CASE WHEN cast(dv.__partition_column as string) LIKE '2026%' THEN dv.sales_volume_official ELSE 0 END) AS hl_26,
    MAX(CASE WHEN dv.sales_volume_official > 0 THEN cast(dv.__partition_column as string) END) AS ult_mes
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice dv
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dv_p on dv_p.product_short_code = dv.product_short_code
  WHERE cast(dv.__partition_column as string) IN ('202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                   '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND dv.invoice_commercial_flag = 1 AND dv_p.product_line IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY dv.sold_to_customer_short_code
),
x AS (
  SELECT c.*, v.hl_25, v.hl_26, v.ult_mes,
    CASE WHEN c.anio_alta < 2025 AND v.hl_25 > 0 AND v.hl_26 <= 0 THEN 'perdido'
         WHEN c.anio_alta >= 2025 AND v.hl_26 > 0 THEN 'nuevo' END AS tipo,
    ROW_NUMBER() OVER (PARTITION BY c.gv, CASE WHEN c.anio_alta < 2025 AND v.hl_25 > 0 AND v.hl_26 <= 0 THEN 'perdido' WHEN c.anio_alta >= 2025 AND v.hl_26 > 0 THEN 'nuevo' END
                       ORDER BY CASE WHEN c.anio_alta < 2025 THEN v.hl_25 ELSE v.hl_26 END DESC) AS rk
  FROM cli c JOIN v ON c.cliente_id = v.cliente_id
)
SELECT gv, tipo, rk, cliente_id, nombre, estado, anio_alta, canal, subcanal, centro_id, ROUND(hl_25) AS hl25, ROUND(hl_26) AS hl26, ult_mes
FROM x WHERE tipo IS NOT NULL AND rk <= 5
ORDER BY gv, tipo, rk
LIMIT 60
