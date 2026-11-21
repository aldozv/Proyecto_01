-- Deep dive GV Pucallpa: HL Beer+Rtds y POCs compradores por CD x supervisor x canal (dm_cliente vigente), sin SJ01.
-- Periodos: YTD25/YTD26 = Ene-Oct, MTD25/MTD26 = 1-16 Nov.
select case when v.mes between '202501' and '202510' then 'YTD25' when v.mes between '202601' and '202610' then 'YTD26'
            when v.fecha_venta between '2025-11-01' and '2025-11-16' then 'MTD25' when v.fecha_venta between '2026-11-01' and '2026-11-16' then 'MTD26' end as periodo,
  c.centro_id, coalesce(c.supervisor,'Sin supervisor') as supervisor, coalesce(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') as canal,
  sum(v.hl) as hl, count(distinct case when v.hl > 0 then v.cliente_id end) as pocs
from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
where v.mes between '202501' and '202611' and v.mes not in ('202512') and v.fecha_venta <= '2026-11-16'
  and c.gerencia = 'PE Ger P4 Pucall Hco' and c.centro_id <> 'SJ01' and v.indicadores_comerciales = 1
  and v.estratificacion in ('Cervezas','Licores','Ready To Drink')
  and not (v.mes = '202511' and v.fecha_venta > '2025-11-16')
group by 1,2,3,4 order by 1,2,3,4 limit 2000
