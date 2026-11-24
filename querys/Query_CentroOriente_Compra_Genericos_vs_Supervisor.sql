/* Clientes de la cartera vigente de Centro Oriente por GV, tipo de supervisor (promotor generico vs supervisor
   real) y fecha de alta, con cuantos compraron (HL > 0, indicadores_comerciales = 1) desde el 01.08.26.
   Mismo alcance y exclusiones que Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql (mes en curso). */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT dm_cliente.customer_short_code as cliente_id FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer dm_cliente
  WHERE UPPER(COALESCE(dm_cliente.sales_subregion_name, '')) LIKE '%PRUEBA%' OR COALESCE(dm_cliente.subchannel_name, '') LIKE 'MTKP%'
),
c AS (
  SELECT c.customer_short_code as cliente_id, REPLACE(c.sales_region_name, 'PE Ger P4 ', '') AS gv,
    CASE WHEN LOWER(c.sales_subregion_name) LIKE '%promotor gen%' THEN 'generico' ELSE 'supervisor' END AS tipo,
    CASE WHEN c.customer_updated_at >= '2026-09-01' THEN 'alta set-nov26' ELSE 'alta previa' END AS alta
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  LEFT ANTI JOIN excl e ON c.customer_short_code = e.cliente_id
  WHERE c.sales_area_name = 'PE Dir Centro Orient' AND c.customer_status = '1' AND LEN(c.customer_short_code) = 8
    AND c.business_unit NOT LIKE 'DAs Sellout' AND c.business_unit NOT LIKE 'Consumidor'
),
v AS (
  SELECT dm_venta.sold_to_customer_short_code as cliente_id, SUM(dm_venta.sales_volume_official) AS hl
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice dm_venta
  WHERE dm_venta.invoice_date >= '2026-08-01' AND dm_venta.invoice_commercial_flag = 1
  GROUP BY dm_venta.sold_to_customer_short_code
)
SELECT c.gv, c.tipo, c.alta, COUNT(*) AS clientes, SUM(CASE WHEN v.hl > 0 THEN 1 ELSE 0 END) AS con_compra_ago_nov26
FROM c LEFT JOIN v ON c.cliente_id = v.cliente_id
GROUP BY 1,2,3
ORDER BY 1,2,3
