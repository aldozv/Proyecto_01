-- Deep dive GV Pucallpa: Volumen (HL Beer+Rtds) y Brand Distribution (SELLIN, recalculado desde dm_venta)
-- por brand_pack x CD x supervisor, en periodos agregados:
--   YTD25 = Ene-Oct'25 | YTD26 = Ene-Oct'26 | MTD25 = 1-16 Nov'25 | MTD26 = 1-16 Nov'26 | FY25 = Ene-Dic'25
-- BD del periodo = suma de los BD mensuales (cliente-material con HL neto > 0 en el mes), como el KPI oficial.
-- GV/CD/supervisor de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan).
with cm as (
  select v.mes,
    case when v.fecha_venta between '2025-11-01' and '2025-11-16' then 1 else 0 end as is_mtd25,
    c.centro_id, coalesce(c.supervisor,'Sin supervisor') as supervisor,
    coalesce(m.brand_pack, 'Sin brand_pack') as brand_pack, v.cliente_id, v.material_id,
    sum(v.hl) as hl,
    sum(case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.hl end) as hlbd
  from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
  left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
  where v.mes between '202501' and '202611' and v.fecha_venta <= '2026-11-16'
    and c.gerencia = 'PE Ger P4 Pucall Hco' and c.centro_id <> 'SJ01' and v.indicadores_comerciales = 1
    and v.estratificacion in ('Cervezas','Licores','Ready To Drink')
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
