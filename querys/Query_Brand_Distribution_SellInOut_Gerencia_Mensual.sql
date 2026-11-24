-- SELLIN/SELLOUT puros por gerencia x mes (SIN exclusion de brand_pack), ene'24-set'26.
-- Alimenta las lineas Total / gerencia del artifact "Brand Distribution - CO" con el filtro Tipo
-- (Sell In / Sell Out). Alcance: Cervezas + Licores + Ready To Drink.
select
    v.gerencia,
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-09-30'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.gerencia, v.mes
order by v.gerencia, v.mes
