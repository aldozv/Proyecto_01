/* Venta Beer+Rtds mensual (ene'23 - oct'26) de los clientes de Centro Oriente, por GV vigente y anio de alta
   del cliente (cohorte), para ver cuanto volumen aporta cada generacion de clientes mes a mes.
   Mismo universo y definicion de cartera que Query_CentroOriente_Venta_Cartera_Cohorte_YTD.sql. */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT dm_cliente.customer_short_code as cliente_id FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer dm_cliente
  WHERE UPPER(COALESCE(dm_cliente.sales_subregion_name, '')) LIKE '%PRUEBA%' OR COALESCE(dm_cliente.subchannel_name, '') LIKE 'MTKP%'
),
cli AS (
  SELECT c.customer_short_code as cliente_id,
    REPLACE(c.sales_region_name, 'PE Ger P4 ', '') AS gv,
    CASE WHEN e.cliente_id IS NULL AND LEN(c.customer_short_code) = 8
          AND c.business_unit NOT LIKE 'DAs Sellout' AND c.business_unit NOT LIKE 'Consumidor'
         THEN 'Cartera' ELSE 'Fuera de cartera' END AS en_cartera,
    CASE WHEN YEAR(c.customer_updated_at) <= 2022 THEN 'Antes de 2023' ELSE CAST(YEAR(c.customer_updated_at) AS STRING) END AS cohorte
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  LEFT JOIN excl e ON c.customer_short_code = e.cliente_id
  WHERE c.sales_area_name = 'PE Dir Centro Orient'
),
v AS (
  SELECT cast(v.__partition_column as string) as mes, v.sold_to_customer_short_code as cliente_id, SUM(v.sales_volume_official) AS hl
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  WHERE cast(v.__partition_column as string) BETWEEN '202301' AND '202610'
    AND v.invoice_commercial_flag = 1
    AND v_p.product_line IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY cast(v.__partition_column as string), v.sold_to_customer_short_code
)
SELECT v.mes, c.gv, c.en_cartera, c.cohorte,
  SUM(v.hl) AS hl,
  SUM(CASE WHEN v.hl > 0 THEN 1 ELSE 0 END) AS compradores
FROM v JOIN cli c ON v.cliente_id = c.cliente_id
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4
