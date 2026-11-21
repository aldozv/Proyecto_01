-- Deep dive GV Pucallpa (17.11.26, v2 con filtros de canal y producto): HL Beer+Rtds y Brand Distribution (SELLIN recalculado)
-- por periodo x CD x supervisor x canal x brand_pack x marca x marca GPA x pack. Reemplaza los 3 archivos anteriores del dashboard.
-- Periodos: meses Ene'25-Nov'26 (Nov'26 = MTD 1-16) + 'MTD2511' = 1-16 Nov'25 (Nov'25 completo tambien va como 202511).
-- BD del mes = # cliente-material con HL neto de BD > 0 en el mes; es aditivo entre CD, supervisor, canal y producto.
-- GV/CD/supervisor/canal de dm_cliente (foto vigente). Sin SJ01 (Planta San Juan). CD fuera de SJ97/SJ90/SJ93 = 'Otros CD'.
-- brand_pack de pe_portfolio_material (mismo maestro que BD); marca, marca_gpa y pack de revenue_maestro_sku.
with base as (
  select case when v.fecha_venta between '2025-11-01' and '2025-11-16' then 1 else 0 end as is_mtd25,
    v.mes,
    case c.centro_id when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' else 'Otros CD' end as cd,
    case when c.supervisor like 'Promotor generico%' then 'Promotores genéricos'
         when upper(c.supervisor) like 'SUPERVISION KA%' then 'Supervisión KA'
         when c.supervisor = 'Trujillo Rubin, Cesar Jose' then 'Jose Trujillo'
         when c.supervisor is null then 'Sin supervisor'
         else initcap(c.supervisor) end as supervisor,
    coalesce(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') as canal,
    coalesce(m.brand_pack, 'Sin brandpack') as brand_pack,
    coalesce(s.marca, 'Sin marca') as marca,
    coalesce(s.marca_gpa, 'Sin marca GPA') as marca_gpa,
    coalesce(s.pack, 'Sin pack') as pack,
    v.cliente_id, v.material_id, v.hl,
    case when m.estratificacion in ('Cervezas','Licores','Ready To Drink')
          and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
         then v.hl end as hl_bd
  from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
  left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
  left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on v.material_id = s.sku
  where v.mes between '202501' and '202611' and v.fecha_venta <= '2026-11-16'
    and c.gerencia = 'PE Ger P4 Pucall Hco' and c.centro_id <> 'SJ01' and v.indicadores_comerciales = 1
    and v.estratificacion in ('Cervezas','Licores','Ready To Drink')
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
