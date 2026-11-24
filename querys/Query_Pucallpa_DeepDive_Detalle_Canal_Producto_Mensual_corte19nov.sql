-- Deep dive GV Pucallpa (20.11.26, v2 con filtros de canal y producto): HL Beer+Rtds y Brand Distribution (SELLIN recalculado)
-- por periodo x CD x supervisor x canal x brand_pack x marca x marca GPA x pack. Reemplaza los 3 archivos anteriores del dashboard.
-- Periodos: meses Ene'25-Nov'26 (Nov'26 = MTD 1-19) + 'MTD2511' = 1-19 Nov'25 (Nov'25 completo tambien va como 202511).
-- BD del mes = # cliente-material con HL neto de BD > 0 en el mes; es aditivo entre CD, supervisor, canal y producto.
-- GV/CD/supervisor/canal de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan). CD fuera de SJ97/SJ90/SJ93 = 'Otros CD'.
-- brand_pack de pe_portfolio_material (mismo maestro que BD); marca, marca_gpa y pack de revenue_maestro_sku.
with base as (
  select case when v.invoice_date between '2025-11-01' and '2025-11-19' then 1 else 0 end as is_mtd25,
    cast(v.__partition_column as string) as mes,
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
    v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, v.sales_volume_official as hl,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.sales_volume_official end as hl_bd
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.sold_to_customer_short_code = c.customer_short_code
  left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.product_short_code = m.material_id
  left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on v.product_short_code = s.sku
  where cast(v.__partition_column as string) between '202501' and '202611' and v.invoice_date <= '2026-11-19'
    and c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.invoice_commercial_flag = 1
    and v_p.product_line in ('Cervezas','Licores','Ready To Drink')
), cm as (
  select mes as periodo, cd, supervisor, canal, brand_pack, marca, marca_gpa, pack, cliente_id, material_id, sum(hl) as hl, sum(hl_bd) as hlbd
  from base group by 1,2,3,4,5,6,7,8,9,10
  union all
  select 'MTD2511', cd, supervisor, canal, brand_pack, marca, marca_gpa, pack, cliente_id, material_id, sum(hl), sum(hl_bd)
  from base where is_mtd25 = 1 group by 2,3,4,5,6,7,8,9,10
)
select periodo, cd, supervisor, canal, brand_pack, marca, marca_gpa, pack,
  round(sum(hl), 3) as hl, sum(case when hlbd > 0 then 1 else 0 end) as bd
from cm
group by 1,2,3,4,5,6,7,8
having abs(sum(hl)) >= 0.0005 or sum(case when hlbd > 0 then 1 else 0 end) > 0
order by 1,2,3,4,5
limit 100000
