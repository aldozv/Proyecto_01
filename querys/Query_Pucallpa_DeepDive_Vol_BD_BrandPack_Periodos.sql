-- Deep dive GV Pucallpa: Volumen (HL Beer+Rtds) y Brand Distribution (SELLIN, recalculado desde dm_venta)
-- por brand_pack x CD x supervisor, en periodos agregados:
--   YTD25 = Ene-Oct'25 | YTD26 = Ene-Oct'26 | MTD25 = 1-22 Nov'25 | MTD26 = 1-22 Nov'26 | FY25 = Ene-Dic'25
-- BD del periodo = suma de los BD mensuales (cliente-material con HL neto > 0 en el mes), como el KPI oficial.
-- GV/CD/supervisor de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan).
with cm as (
  select cast(v.__partition_column as string) as mes,
    case when v.invoice_date between '2025-11-01' and '2025-11-22' then 1 else 0 end as is_mtd25,
    c.distribution_center_code as centro_id, coalesce(c.sales_subregion_name,'Sin supervisor') as supervisor,
    coalesce(m.brand_pack, 'Sin brand_pack') as brand_pack, v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id,
    sum(v.sales_volume_official) as hl,
    sum(case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.sales_volume_official end) as hlbd
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.sold_to_customer_short_code = c.customer_short_code
  left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.product_short_code = m.material_id
  where cast(v.__partition_column as string) between '202501' and '202611' and v.invoice_date <= '2026-11-22'
    and c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.invoice_commercial_flag = 1
    and v_p.product_line in ('Cervezas','Licores','Ready To Drink')
  group by 1,2,3,4,5,6,7
), mes_cm as (  -- BD mensual (mes completo) por cliente-material
  select mes, centro_id, supervisor, brand_pack, cliente_id, material_id, sum(hl) as hl, sum(hlbd) as hlbd
  from cm group by 1,2,3,4,5,6
), mtd25_cm as (
  select centro_id, supervisor, brand_pack, cliente_id, material_id, sum(hl) as hl, sum(hlbd) as hlbd
  from cm where is_mtd25 = 1 group by 1,2,3,4,5
), per as (
  select case when mes between '202501' and '202510' then 'YTD25'
              when mes between '202601' and '202610' then 'YTD26'
              when mes = '202611' then 'MTD26' end as periodo,
         centro_id, supervisor, brand_pack, hl, case when hlbd > 0 then 1 else 0 end as bd
  from mes_cm where mes not in ('202511','202512')
  union all
  select 'FY25', centro_id, supervisor, brand_pack, hl, case when hlbd > 0 then 1 else 0 end from mes_cm where mes like '2025%'
  union all
  select 'MTD25', centro_id, supervisor, brand_pack, hl, case when hlbd > 0 then 1 else 0 end from mtd25_cm
)
select periodo, centro_id, supervisor, brand_pack, sum(hl) as hl, sum(bd) as bd
from per group by 1,2,3,4 order by 1,2,3,4
limit 20000
