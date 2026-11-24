-- Deep dive BD Lima: BD recalculado desde dm_venta (1 punto por cliente-material con caja_fisica > 0 en el mes), Set y Oct'26,
-- por gerencia x canal x SKU, con POCs. Set'26 sirve para el factor recalculo/oficial; Oct'26 se escala con ese factor.
with s as (
  select v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, cast(v.__partition_column as string) as mes
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
  where cast(v.__partition_column as string) in ('202609','202610') and v.invoice_date between '2026-09-01' and '2026-10-31' and v.invoice_commercial_flag = 1
  group by 1,2,3 having sum(v.billed_sales_boxes_quantity) > 0
)
select v.mes, c.sales_region_name as gerencia, coalesce(c.business_unit_target_volume,'Sin clasificar') as canal, m.estratificacion,
  case when d.brand_name in ('Pilsen Fresh','Pilsen Callao Fresh') then 'Pilsen Fresh'
       when d.brand_name in ('Corona Cero','Cusqueña Cero Trigo') then 'Non Alc'
       when d.brand_name = 'Flying Fish' then 'Flying Fish'
       when m.brand = 'P.Callao' then 'Pilsen Callao'
       else m.brand end as marca_grp, case when d.brand_name in ('Pilsen Fresh','Pilsen Callao Fresh') then concat('Pilsen Fresh ', m.pack)
       when d.brand_name = 'Corona Cero' then concat('Corona Cero ', m.pack)
       when d.brand_name = 'Cusqueña Cero Trigo' then concat('Cusqueña Cero ', m.pack)
       when d.brand_name = 'Flying Fish' then concat('Flying Fish ', m.pack)
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand = 'P.Callao' then concat('Pilsen Callao ', m.pack)
       else m.brand_pack end as bp, m.pack, v.material_id, d.product_name as nombre, count(*) as bd
from s v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = v.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product d on d.product_short_code = v.material_id
where c.sales_area_name = 'PE Dir Lima' and c.sales_region_name like 'PE Ger P1%' and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3,4,5,6,7,8,9
limit 60000
