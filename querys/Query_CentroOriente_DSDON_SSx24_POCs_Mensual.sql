/* DSD ON Centro Oriente: POCs compradores Beer+Rtds y POCs que compran SS x24, y HL/NR de SS x24, por gerencia y mes
   Ene'23-Oct'26 (para cobertura de SS x24, tendencia mensual y precio NR/HL). POC comprador = HL > 0 en el mes. */
WITH cli AS (
  SELECT c.customer_short_code as cliente_id, REPLACE(c.sales_region_name, 'PE Ger P4 ', '') AS gv
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  WHERE c.sales_area_name = 'PE Dir Centro Orient'
    AND c.business_unit_target_volume IN ('DSD ON', 'High End')
),
cm AS (
  SELECT cast(v.__partition_column as string) as mes, cli.gv, v.sold_to_customer_short_code as cliente_id,
    SUM(v.sales_volume_official) AS hl,
    SUM(CASE WHEN r.`Agrupador (Tipo 2.0)` = 'SS x 24' THEN v.sales_volume_official ELSE 0 END) AS hl_ss24,
    SUM(CASE WHEN r.`Agrupador (Tipo 2.0)` = 'SS x 24' THEN v.net_revenue_amount ELSE 0 END) AS nr_ss24
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  JOIN cli ON v.sold_to_customer_short_code = cli.cliente_id
  LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.product_short_code = r.sku
  WHERE cast(v.__partition_column as string) >= '202301' AND cast(v.__partition_column as string) <= '202610'
    AND v.invoice_commercial_flag = 1
    AND v_p.product_line IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY 1, 2, 3
)
SELECT mes, gv,
  SUM(CASE WHEN hl > 0 THEN 1 ELSE 0 END) AS pocs,
  SUM(CASE WHEN hl_ss24 > 0 THEN 1 ELSE 0 END) AS pocs_ss24,
  SUM(hl) AS hl, SUM(hl_ss24) AS hl_ss24, SUM(nr_ss24) AS nr_ss24
FROM cm
GROUP BY 1, 2
ORDER BY 1, 2
