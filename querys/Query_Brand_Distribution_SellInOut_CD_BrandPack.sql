-- SELLIN/SELLOUT puros (sin la regla oficial mixta por gerencia) por CD x brand_pack x mes,
-- ene'24-ago'26. Alimenta el filtro "Tipo" (Total oficial / Sell In / Sell Out) del artifact
-- "Evolución de Brand Distribution" para la vista por CD.
select
    c.centro_id,
    m.brand_pack,
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-08-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and m.brand_pack not in ('N.A', 'Corona Tropical 355 CAN', 'P.Trujillo 620 RB', 'P.Trujillo 473 CAN',
                          'P.Trujillo 355 CAN', 'Arequipeña 620 RB', 'Arequipeña 473 CAN',
                          'Kauffmann 355 CAN', 'Pacífico Clara 355 CAN', 'Barbarian 269 CAN')
and c.centro_id in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
group by c.centro_id, m.brand_pack, v.mes
order by c.centro_id, m.brand_pack, v.mes
