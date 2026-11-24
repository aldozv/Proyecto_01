-- SELLIN/SELLOUT puros por CD x mes (SIN exclusion de brand_pack), ene'24-set'26.
-- Nota: el SELLOUT no se puede atribuir a un CD (cliente_id de SELLOUT no existe en dm_cliente),
-- asi que a nivel CD el SELLOUT sale en cero -- limitacion de origen, ver BITACORA_TABLAS.md.
select
    c.distribution_center_code as centro_id,
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-09-30'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and c.distribution_center_code in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
group by c.distribution_center_code, v.mes
order by c.distribution_center_code, v.mes
