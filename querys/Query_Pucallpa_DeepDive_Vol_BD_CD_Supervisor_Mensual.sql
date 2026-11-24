-- Deep dive GV Pucallpa: Volumen (HL Beer+Rtds) y Brand Distribution (SELLIN) por mes x CD x supervisor.
-- Periodos: Ene'25-Nov'26 (Nov'26 = MTD 1-22) + 'MTD2511' = 1-22 Nov'25 (comparable MTD LY).
-- GV, CD y supervisor de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan).
-- BD recalculado desde dm_venta: # cliente-material con HL neto > 0 en el periodo (la tabla oficial
-- pe_portfolio_hm_brand_distribution corta al 22-Oct'26; validado: recalculo ~+0.8% vs tabla en mar/set/oct'25 y set'26).
with base as (
  select case when v.invoice_date between '2025-11-01' and '2025-11-22' then 'MTD2511' else cast(v.__partition_column as string) end as periodo,
    cast(v.__partition_column as string) as mes, c.distribution_center_code as centro_id, c.distribution_center_name as centro, coalesce(c.sales_subregion_name,'Sin supervisor') as supervisor, v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id,
    case when v_p.product_line in ('Cervezas','Licores','Ready To Drink') then v.sales_volume_official else 0 end as hl_vol,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.sales_volume_official else null end as hl_bd
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.sold_to_customer_short_code = c.customer_short_code
  left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.product_short_code = m.material_id
  where cast(v.__partition_column as string) between '202501' and '202611' and v.invoice_date <= '2026-11-22'
    and c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.invoice_commercial_flag = 1
    and v_p.product_line in ('Cervezas','Licores','Ready To Drink')
), mtd25 as (
  select * from base where periodo = 'MTD2511'
), todo as (
  select periodo, centro_id, centro, supervisor, cliente_id, material_id, hl_vol, hl_bd from base
  union all
  select mes, centro_id, centro, supervisor, cliente_id, material_id, hl_vol, hl_bd from mtd25  -- Nov'25 completo tambien
), cm as (
  select periodo, centro_id, centro, supervisor, cliente_id, material_id, sum(hl_vol) as hl, sum(hl_bd) as hlbd
  from todo group by 1,2,3,4,5,6
)
select periodo, centro_id, centro, supervisor,
  sum(hl) as hl,
  sum(case when hlbd > 0 then 1 else 0 end) as bd,
  count(distinct case when hlbd > 0 then cliente_id end) as pocs_bd
from cm group by 1,2,3,4 order by 1,2,4
