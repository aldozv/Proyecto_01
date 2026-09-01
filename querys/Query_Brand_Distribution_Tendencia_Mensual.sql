-- Brand Distribution: tendencia mensual, Direccion Centro Oriente, SELLIN vs SELLOUT + Total
-- Alcance: solo Cervezas + Licores + Ready To Drink (excluye Marketplace/NABs, confirmado con usuario 2026-08-31)
select
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout,
    sum(v.flag_brand_distro) as sellin_mas_sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-08-01' and '2026-08-30'
-- ago 2026 es MTD (hoy 31.08, dato disponible solo hasta dia -1 = 30.08); se excluye el 31.08.25
-- del mismo mes en 2025 para comparar YoY con el mismo corte de dias
and not (v.mes = '202508' and day(v.fecha_venta) = 31)
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.mes
order by v.mes
