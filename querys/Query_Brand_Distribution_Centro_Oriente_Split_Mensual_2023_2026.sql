-- v8 PR 2026: Brand Distribution oficial por gerencia x zona (Centro / Oriente) x mes, Ene'23-Oct'26, Beer+Rtds
-- Centro = GV Huancay Ch con clientes de los CD Huancayo (BK68) y Huancavelica (BK43); resto = Oriente
-- (incluye Satipo SJ86, Chanchamayo SJ87 y DA Jun Puc, que es Sell Out sin CD). Regla oficial por GV.
select v.gerencia,
 case when c.centro_id in ('BK68', 'BK43') then 'CENTRO_CD' else 'OTRO_CD' end as zona_cd,
 v.mes,
 sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
 sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2023-01-01' and '2026-10-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.gerencia, case when c.centro_id in ('BK68', 'BK43') then 'CENTRO_CD' else 'OTRO_CD' end, v.mes
limit 2000
