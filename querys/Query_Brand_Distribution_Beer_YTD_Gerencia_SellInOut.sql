-- Brand Distribution Beer (Cervezas + Licores), YTD ene-set 2026 vs 2025 (suma de meses), por
-- gerencia abierto por SELLIN / SELLOUT puros (sin aplicar la regla oficial por gerencia).
select
    v.gerencia,
    left(v.mes,4) as anio,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.mes in ('202501','202502','202503','202504','202505','202506','202507','202508','202509',
              '202601','202602','202603','202604','202605','202606','202607','202608','202609')
and m.estratificacion in ('Cervezas', 'Licores')
and m.brand_pack <> 'N.A'
group by v.gerencia, left(v.mes,4)
order by v.gerencia, anio
