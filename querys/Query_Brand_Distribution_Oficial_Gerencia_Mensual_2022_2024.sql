-- Brand Distribution oficial por gerencia x mes, todo el historico disponible antes de 2025 (chequeo 2023-2024), Beer+Rtds.
select v.gerencia, v.mes,
 sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
 sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2022-01-01' and '2024-12-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.gerencia, v.mes
order by v.gerencia, v.mes
limit 1000
