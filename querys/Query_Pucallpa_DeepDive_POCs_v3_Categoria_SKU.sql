-- Deep dive GV Pucallpa v3 (23.11.26): POCs compradores por periodo x CD x supervisor x canal, MTD = facturado 1-22 Nov + plan del 23 vs 1-23 Nov 2025.
-- Reemplaza a Query_Pucallpa_DeepDive_POCs_Canal_Producto_Periodos.sql: agrega las dimensiones categoria (Beer/Rtds), agrupador y sku.
-- para el total (dim = 'Total') y para cada valor de producto (dim = brand_pack | marca | marca_gpa | pack | pack_xxx).
-- Los POCs no se suman entre productos (un cliente compra varios), por eso van precalculados por cada valor.
--   pm = suma de los POCs de cada mes (YTD: Ene-Oct; /10 en el dashboard = promedio mensual). MTD: 1-22 Nov facturado + plan del 23 (2026) vs 1-23 Nov (2025).
--   pd = POCs distintos en todo el periodo (usado en la tabla por canal).
-- POC = cliente con HL de BD > 0 (alcance de Brand Distribution) en el mes / periodo, como en la version anterior del dashboard.
-- pack_xxx = primer digito de la capacidad + XX (1000+ = 1XXX) + tipo de envase, ej. 620 RB -> 6XX RB, 355 CAN -> 3XX CAN.
with v as (  -- venta facturada + plan de entrega de hoy (23-Nov-26) como si fuera venta del 23
  select cast(dm_venta.__partition_column as string) as mes, dm_venta.invoice_date as fecha_venta, dm_venta.sold_to_customer_short_code as cliente_id, dm_venta.product_short_code as material_id, dm_venta.sales_volume_official as hl, dm_venta_p.product_line as estratificacion, dm_venta.invoice_commercial_flag as indicadores_comerciales
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice dm_venta
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm_venta_p on dm_venta_p.product_short_code = dm_venta.product_short_code
  where cast(dm_venta.__partition_column as string) between '202501' and '202611' and dm_venta.invoice_date <= '2026-11-24'
  union all
  select '202611', a.planned_delivery_date as FechaPlan, a.customer_short_code as CodCliente, a.product_short_code as SKU, a.planned_volume_hl as HLPlaneado,
    case d.categoria when 'Ready to drink' then 'Ready To Drink' else d.categoria end, 1
  from brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order a
  join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code
  where a.planned_delivery_date = '2026-11-25' and a.customer_short_code > 10000000 and d.categoria in ('Cervezas','Licores','Ready to drink')
), base as (
  select case when v.mes between '202501' and '202510' then 'YTD25' when v.mes between '202601' and '202610' then 'YTD26'
              when v.fecha_venta between '2025-11-01' and '2025-11-25' then 'MTD25' when v.fecha_venta between '2026-11-01' and '2026-11-25' then 'MTD26' end as periodo,
    v.mes,
    case c.distribution_center_code when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' else 'Otros CD' end as cd,
    case when c.sales_subregion_name like 'Promotor generico%' then 'Promotores genéricos'
         when upper(c.sales_subregion_name) like 'SUPERVISION KA%' then 'Supervisión KA'
         when c.sales_subregion_name = 'Trujillo Rubin, Cesar Jose' then 'Jose Trujillo'
         when c.sales_subregion_name is null then 'Sin supervisor'
         else initcap(c.sales_subregion_name) end as supervisor,
    coalesce(c.business_unit_target_volume, 'Sin clasificar') as canal,
    coalesce(m.brand_pack, 'Sin brandpack') as brand_pack,
    coalesce(s.marca, 'Sin marca') as marca,
    coalesce(s.marca_gpa, 'Sin marca GPA') as marca_gpa,
    coalesce(s.pack, 'Sin pack') as pack,
    case when v.estratificacion in ('Cervezas','Licores') then 'Beer' else 'Rtds' end as categoria,
    coalesce(s.`Agrupador (Sku)`, 'Sin agrupador') as agrupador,
    concat(regexp_replace(cast(v.material_id as string), '^0+', ''), ' - ', coalesce(dm.product_name, 'Sin nombre')) as sku,
    v.cliente_id, v.material_id,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.hl end as hl_bd
  from v
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.cliente_id = c.customer_short_code
  left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
  left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on v.material_id = s.sku
  left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm on v.material_id = dm.product_short_code
  where v.mes between '202501' and '202611' and v.mes <> '202512' and v.fecha_venta <= '2026-11-25'
    and not (v.mes = '202511' and v.fecha_venta > '2025-11-25')
    and c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.indicadores_comerciales = 1
    and v.estratificacion in ('Cervezas','Licores','Ready To Drink')
), b2 as (
  select *, case when regexp_extract(pack, '^([0-9]+)', 1) = '' then pack
                 when cast(regexp_extract(pack, '^([0-9]+)', 1) as int) >= 1000 then concat('1XXX ', trim(regexp_replace(pack, '^[0-9]+', '')))
                 else concat(substr(pack, 1, 1), 'XX ', trim(regexp_replace(pack, '^[0-9]+', ''))) end as pack_xxx
  from base where periodo is not null
), dims as (
  select periodo, mes, cd, supervisor, canal, cliente_id, material_id, d.dim, d.valor, hl_bd
  from b2 lateral view stack(9, 'Total', 'Total', 'categoria', categoria, 'brand_pack', brand_pack, 'marca', marca, 'marca_gpa', marca_gpa, 'pack', pack, 'pack_xxx', pack_xxx, 'agrupador', agrupador, 'sku', sku) d as dim, valor
), cm as (  -- cliente-material: POC si al menos un material tiene HL de BD neto > 0 (mismo criterio que el BD)
  select periodo, mes, cd, supervisor, canal, dim, valor, cliente_id, material_id, sum(hl_bd) as hlbd
  from dims group by 1,2,3,4,5,6,7,8,9
), cli_mes as (
  select periodo, mes, cd, supervisor, canal, dim, valor, cliente_id, max(case when hlbd > 0 then 1 else 0 end) as hlbd
  from cm group by 1,2,3,4,5,6,7,8
), mensual as (
  select periodo, cd, supervisor, canal, dim, valor, sum(case when hlbd > 0 then 1 else 0 end) as pm
  from cli_mes group by 1,2,3,4,5,6
), cli_per as (
  select periodo, cd, supervisor, canal, dim, valor, cliente_id, max(case when hlbd > 0 then 1 else 0 end) as compra
  from cli_mes group by 1,2,3,4,5,6,7
), distintos as (
  select periodo, cd, supervisor, canal, dim, valor, sum(compra) as pd
  from cli_per group by 1,2,3,4,5,6
)
select m.periodo, m.cd, m.supervisor, m.canal, m.dim, m.valor, m.pm, d.pd
from mensual m join distintos d using (periodo, cd, supervisor, canal, dim, valor)
where m.pm > 0 or d.pd > 0
order by 1,2,3,4,5,6
limit 300000
