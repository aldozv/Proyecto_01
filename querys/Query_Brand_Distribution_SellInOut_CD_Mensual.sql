-- SELLIN/SELLOUT puros por CD x mes (SIN exclusion de brand_pack), ene'24-set'26.
-- Nota: el SELLOUT no se puede atribuir a un CD (cliente_id de SELLOUT no existe en dm_cliente),
-- asi que a nivel CD el SELLOUT sale en cero -- limitacion de origen, ver BITACORA_TABLAS.md.
select
    c.centro_id,
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-09-30'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and c.centro_id in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
group by c.centro_id, v.mes
order by c.centro_id, v.mes
