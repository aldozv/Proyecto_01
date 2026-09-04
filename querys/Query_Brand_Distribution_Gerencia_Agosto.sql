-- Brand Distribution SELLIN vs SELLOUT por gerencia, agosto 2025 vs 2026 (mes cerrado completo en
-- ambos anios). Alcance: Cervezas + Licores + Ready To Drink, Direccion Centro Oriente.
-- OJO: el "total oficial" por gerencia NO es SELLIN+SELLOUT parejo en las 5 GV -- depende de que
-- tipo reporta cada una (confirmado por el usuario 2026-08-31, ver CLAUDE.md):
--   Pucall Hco y Huancay Ch -> solo SELLIN
--   Iquitos y Tarapoto      -> SELLIN + SELLOUT
--   DA Jun Puc              -> solo SELLOUT
select
    v.gerencia,
    v.mes,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as brand_distribution_oficial
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.mes in ('202508','202608')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.gerencia, v.mes
order by v.gerencia, v.mes
