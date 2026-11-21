-- SKUs en quiebre por CD x brand_pack, YTD'26 (Ene-Oct). Complemento de Query_OOS_DeepDive_GV_CD_BrandPack_Mensual.sql.
-- skus_oos_list = codigos SAP separados por coma; se explotan y se cruzan con dm_material para el nombre.
with s as (
    select distinct v.centro_id, v.brand_pack, trim(x) as material_id
    from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
    lateral view explode(split(v.skus_oos_list, ',')) e as x
    where v.mes between '202601' and '202610'
    and v.activo_en_cd = 1
    and v.horas_oos_brand_pack > 0
    and v.centro_id in ('BK43','BK68','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
    and dayofweek(v.out_of_stock_date) <> 1
)
select s.centro_id, s.brand_pack, s.material_id, max(m.nombre) as nombre
from s
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
    on ltrim('0', m.material_id) = ltrim('0', s.material_id)
group by 1, 2, 3
order by 1, 2, 3
limit 5000
