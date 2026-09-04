-- Brand Distribution oficial por gerencia x brand_pack, YTD ene-ago 2025 vs 2026 (mes cerrado).
-- Usar para identificar que brand_pack estan cayendo dentro de cada gerencia, incluso cuando el
-- total de la gerencia crece (crecimiento de otros SKUs puede estar tapando caidas puntuales).
select
    v.gerencia,
    left(v.mes,4) as anio,
    m.brand_pack,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.mes in ('202501','202502','202503','202504','202505','202506','202507','202508',
              '202601','202602','202603','202604','202605','202606','202607','202608')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and m.brand_pack <> 'N.A'
group by v.gerencia, left(v.mes,4), m.brand_pack
order by v.gerencia, m.brand_pack, anio
