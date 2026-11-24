-- Brand Distribution Oct'26 Lima (SELLIN, Beer+Rtds, gerencia vigente dm_cliente) estimado: pe_portfolio_hm_brand_distribution corta al 22.10.26.
-- Metodo: Oct'26 = recalculo dm_venta Oct'26 / (recalculo / oficial de Set'26), por GV. El sesgo recalculo/oficial en Lima es +4% a +13%
-- (mayor que en CO) y sube ~2-3 pp en 2026 vs 2025, pero es estable de un mes al siguiente (Set->Oct'25 difiere <0.3 pp). Corrido 2026-11-21.
with s as (
  select v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, cast(v.__partition_column as string) as mes
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
  where cast(v.__partition_column as string) in ('202509','202510','202609','202610')
    and v.invoice_date between '2025-09-01' and '2026-10-31'
    and v.invoice_commercial_flag = 1
  group by 1,2,3 having sum(v.billed_sales_boxes_quantity) > 0
),
r as (
  select c.sales_region_name as gerencia, s.mes, s.cliente_id, s.material_id, 1 as rec, 0 as ofi
  from s join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = s.cliente_id
  where c.sales_area_name = 'PE Dir Lima'
  union all
  select c.sales_region_name as gerencia, b.mes, b.cliente_id, b.material_id, 0, b.flag_brand_distro
  from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = b.cliente_id
  where b.mes in ('202509','202510','202609') and b.tipo = 'SELLIN' and c.sales_area_name = 'PE Dir Lima'
)
select r.gerencia, r.mes,
  case when m.brand_pack in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN',
       'Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN') then 'EXCL' else 'OK' end as grp,
  sum(r.rec) as recalc, sum(r.ofi) as oficial
from r join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = r.material_id
where m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3
order by 1,3,2
limit 300
