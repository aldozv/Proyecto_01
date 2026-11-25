-- Deep dive GV Pucallpa v3 (23.11.26): HL y Brand Distribution (SELLIN recalculado) por periodo x CD x supervisor x canal
-- x categoria (Beer/Rtds/Nabs) x brand_pack x marca x marca GPA x pack x agrupador (SKU) x SKU.
-- Reemplaza a Query_Pucallpa_DeepDive_Detalle_Canal_Producto_Mensual.sql (agrega Nabs, agrupador y SKU).
-- Periodos: meses Ene'25-Nov'26. 202611 = facturado 1-24 Nov + plan de entrega del 25-Nov; MTD2511 = facturado 1-25 Nov'25.
--   PLAN2611 = solo el plan del 23-Nov (referencia para la tarjeta).
-- Beer = Cervezas+Licores; Rtds = Ready To Drink; Nabs = Gaseosas+Agua+Maltas sin San Mateo. BD solo Beer+Rtds (Nabs = 0).
-- GV/CD/supervisor/canal de dm_cliente (foto vigente). Sin SJ01. Marca/GPA/pack/agrupador de revenue_maestro_sku; SKU = codigo (sin ceros a la izquierda) + ' - ' + nombre de dm_material.
with v as (
  select cast(dm_venta.__partition_column as string) as mes, dm_venta.invoice_date as fecha_venta, dm_venta.sold_to_customer_short_code as cliente_id, dm_venta.product_short_code as material_id, dm_venta.sales_volume_official as hl, dm_venta_p.product_line as estratificacion, dm_venta.invoice_commercial_flag as indicadores_comerciales, 0 as es_plan
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice dm_venta
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm_venta_p on dm_venta_p.product_short_code = dm_venta.product_short_code
  where cast(dm_venta.__partition_column as string) between '202501' and '202611' and dm_venta.invoice_date <= '2026-11-24'
  union all
  select '202611', a.planned_delivery_date as FechaPlan, a.customer_short_code as CodCliente, a.product_short_code as SKU, a.planned_volume_hl as HLPlaneado,
    case d.categoria when 'Ready to drink' then 'Ready To Drink' else d.categoria end, 1, 1
  from brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order a
  join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code
  where a.planned_delivery_date = '2026-11-25' and a.customer_short_code > 10000000
    and d.categoria in ('Cervezas','Licores','Ready to drink','Gaseosas','Agua','Maltas')
), base as (
  select case when v.fecha_venta between '2025-11-01' and '2025-11-25' then 1 else 0 end as is_mtd25,
    v.es_plan, v.mes,
    case c.distribution_center_code when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' else 'Otros CD' end as cd,
    case when c.sales_subregion_name like 'Promotor generico%' then 'Promotores genéricos'
         when upper(c.sales_subregion_name) like 'SUPERVISION KA%' then 'Supervisión KA'
         when c.sales_subregion_name = 'Trujillo Rubin, Cesar Jose' then 'Jose Trujillo'
         when c.sales_subregion_name is null then 'Sin supervisor'
         else initcap(c.sales_subregion_name) end as supervisor,
    coalesce(c.business_unit_target_volume, 'Sin clasificar') as canal,
    case when v.estratificacion in ('Cervezas','Licores') then 'Beer' when v.estratificacion = 'Ready To Drink' then 'Rtds' else 'Nabs' end as categoria,
    coalesce(m.brand_pack, 'Sin brandpack') as brand_pack,
    coalesce(s.marca, 'Sin marca') as marca,
    coalesce(s.marca_gpa, 'Sin marca GPA') as marca_gpa,
    coalesce(s.pack, 'Sin pack') as pack,
    coalesce(s.`Agrupador (Sku)`, 'Sin agrupador') as agrupador,
    concat(regexp_replace(cast(v.material_id as string), '^0+', ''), ' - ', coalesce(dm.product_name, 'Sin nombre')) as sku,
    v.cliente_id, v.material_id, v.hl,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.hl end as hl_bd
  from v
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.cliente_id = c.customer_short_code
  left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
  left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on v.material_id = s.sku
  left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm on v.material_id = dm.product_short_code
  where c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.indicadores_comerciales = 1
    and v.estratificacion in ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
    and not (v.estratificacion = 'Agua' and coalesce(s.marca, '') = 'San Mateo')
), cm as (
  select mes as periodo, cd, supervisor, canal, categoria, brand_pack, marca, marca_gpa, pack, agrupador, sku, cliente_id, material_id, sum(hl) as hl, sum(hl_bd) as hlbd
  from base group by 1,2,3,4,5,6,7,8,9,10,11,12,13
  union all
  select 'MTD2511', cd, supervisor, canal, categoria, brand_pack, marca, marca_gpa, pack, agrupador, sku, cliente_id, material_id, sum(hl), sum(hl_bd)
  from base where is_mtd25 = 1 group by 2,3,4,5,6,7,8,9,10,11,12,13
  union all
  select 'PLAN2611', cd, supervisor, canal, categoria, brand_pack, marca, marca_gpa, pack, agrupador, sku, cliente_id, material_id, sum(hl), 0
  from base where es_plan = 1 group by 2,3,4,5,6,7,8,9,10,11,12,13
)
select periodo, cd, supervisor, canal, categoria, brand_pack, marca, marca_gpa, pack, agrupador, sku,
  round(sum(hl), 3) as hl, sum(case when periodo <> 'PLAN2611' and hlbd > 0 then 1 else 0 end) as bd
from cm
group by 1,2,3,4,5,6,7,8,9,10,11
having abs(sum(hl)) >= 0.0005 or sum(case when periodo <> 'PLAN2611' and hlbd > 0 then 1 else 0 end) > 0
order by 1,2,3,4,5,6
limit 200000
