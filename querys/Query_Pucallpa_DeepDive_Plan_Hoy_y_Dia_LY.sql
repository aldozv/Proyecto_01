-- Deep dive GV Pucallpa: complemento para "MTD con plan de hoy" (23.11.26).
--   PLAN2611  = plan de entrega de HOY (revenue_h_pv_planeada, FechaPlan = hoy Lima), HL Beer+Rtds.
--   DIA251123 = facturado real del mismo dia del año pasado (23-Nov-2025), para comparar 1-23 Nov vs 1-23 Nov.
-- Mismo grano y mismos mapeos que Query_Pucallpa_DeepDive_Detalle_Canal_Producto_Mensual.sql (bd = 0: la tarjeta es solo volumen).
-- Beer+Rtds del plan via revenue_maestro_sku.categoria (deja fuera Marketplace y SKU sin categoria, regla del tracking diario).
with cli as (
  select c.customer_short_code as cliente_id,
    case c.distribution_center_code when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' else 'Otros CD' end as cd,
    case when c.sales_subregion_name like 'Promotor generico%' then 'Promotores genéricos'
         when upper(c.sales_subregion_name) like 'SUPERVISION KA%' then 'Supervisión KA'
         when c.sales_subregion_name = 'Trujillo Rubin, Cesar Jose' then 'Jose Trujillo'
         when c.sales_subregion_name is null then 'Sin supervisor'
         else initcap(c.sales_subregion_name) end as supervisor,
    coalesce(c.business_unit_target_volume, 'Sin clasificar') as canal
  from brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  where c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01'
), x as (
  select 'PLAN2611' as periodo, a.customer_short_code as cliente_id, a.product_short_code as material_id, a.planned_volume_hl as hl
  from brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order a
  join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code
  where a.planned_delivery_date = cast(dateadd(hour, -5, current_timestamp()) as date) and a.customer_short_code > 10000000
    and d.categoria in ('Cervezas','Licores','Ready to drink')
  union all
  select 'DIA251123', v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, v.sales_volume_official as hl
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  where cast(v.__partition_column as string) = '202511' and v.invoice_date = '2025-11-23' and v.invoice_commercial_flag = 1
    and v_p.product_line in ('Cervezas','Licores','Ready To Drink')
)
select x.periodo, cli.cd, cli.supervisor, cli.canal,
  coalesce(m.brand_pack, 'Sin brandpack') as brand_pack, coalesce(s.marca, 'Sin marca') as marca,
  coalesce(s.marca_gpa, 'Sin marca GPA') as marca_gpa, coalesce(s.pack, 'Sin pack') as pack,
  round(sum(x.hl), 3) as hl, 0 as bd
from x join cli on cli.cliente_id = x.cliente_id
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on x.material_id = m.material_id
left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on x.material_id = s.sku
group by 1,2,3,4,5,6,7,8
having abs(sum(x.hl)) >= 0.0005
order by 1,2,3,4,5
limit 20000
