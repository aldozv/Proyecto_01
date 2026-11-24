-- Deep dive BD Lima: POCs con compra Beer+Rtds desde dm_venta por gerencia x canal, Set y Oct'26 (para escalar POCs de Oct'26)
with s as (
  select v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, cast(v.__partition_column as string) as mes
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
  where cast(v.__partition_column as string) in ('202609','202610') and v.invoice_date between '2026-09-01' and '2026-10-31' and v.invoice_commercial_flag = 1
  group by 1,2,3 having sum(v.billed_sales_boxes_quantity) > 0
)
select v.mes, c.sales_region_name as gerencia, coalesce(c.business_unit_target_volume,'Sin clasificar') as canal, count(distinct v.cliente_id) as pocs
from s v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = v.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product d on d.product_short_code = v.material_id
where c.sales_area_name = 'PE Dir Lima' and c.sales_region_name like 'PE Ger P1%' and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3
limit 500
