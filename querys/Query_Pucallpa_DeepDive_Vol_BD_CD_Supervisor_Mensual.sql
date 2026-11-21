-- Deep dive GV Pucallpa: Volumen (HL Beer+Rtds) y Brand Distribution (SELLIN) por mes x CD x supervisor.
-- Periodos: Ene'25-Nov'26 (Nov'26 = MTD 1-16) + 'MTD2511' = 1-16 Nov'25 (comparable MTD LY).
-- GV, CD y supervisor de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan).
-- BD recalculado desde dm_venta: # cliente-material con HL neto > 0 en el periodo (la tabla oficial
-- pe_portfolio_hm_brand_distribution corta al 22-Oct'26; validado: recalculo ~+0.8% vs tabla en mar/set/oct'25 y set'26).
with base as (
  select case when v.fecha_venta between '2025-11-01' and '2025-11-16' then 'MTD2511' else v.mes end as periodo,
    v.mes, c.centro_id, c.centro, coalesce(c.supervisor,'Sin supervisor') as supervisor, v.cliente_id, v.material_id,
    case when v.estratificacion in ('Cervezas','Licores','Ready To Drink') then v.hl else 0 end as hl_vol,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.hl else null end as hl_bd
  from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
  left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
  where v.mes between '202501' and '202611' and v.fecha_venta <= '2026-11-16'
    and c.gerencia = 'PE Ger P4 Pucall Hco' and c.centro_id <> 'SJ01' and v.indicadores_comerciales = 1
    and v.estratificacion in ('Cervezas','Licores','Ready To Drink')
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
