-- v7 lamina BD: stock outs de los 5 SKUs pedidos por el usuario, Ene-Oct 2025 y 2026, CDs de Centro Oriente
select v.brand_pack, substr(v.mes,1,4) as anio,
  count(distinct v.centro_id) as cds, count(distinct v.out_of_stock_date) as dias_con_oos,
  sum(v.horas_oos_brand_pack) as h_oos, sum(v.hl_so_brand_pack) as hl_perdido
from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
where (v.mes between '202501' and '202510' or v.mes between '202601' and '202610')
and v.activo_en_cd = 1
and v.centro_id in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
and v.brand_pack in ('San Juan 355 CAN','Cristal 355 CAN','Cristal 650 RB','Golden 473 CAN','Corona 210 NRB')
group by 1,2
limit 100
