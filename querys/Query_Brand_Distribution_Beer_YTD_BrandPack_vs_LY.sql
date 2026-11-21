-- Brand Distribution oficial, solo categoria Beer (Cervezas + Licores), por brand_pack, Direccion
-- Centro Oriente, YTD ene-set 2026 vs 2025 (mes cerrado). YTD = suma de los valores mensuales,
-- igual que el "Acumulado" del artifact "Brand Distribution - CO".
-- Total oficial por gerencia: Pucall Hco/Huancay Ch solo SELLIN; Iquitos/Tarapoto SELLIN+SELLOUT;
-- DA Jun Puc solo SELLOUT.
select
    m.brand_pack,
    left(v.mes,4) as anio,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as bd_ytd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.mes in ('202501','202502','202503','202504','202505','202506','202507','202508','202509',
              '202601','202602','202603','202604','202605','202606','202607','202608','202609')
and m.estratificacion in ('Cervezas', 'Licores')
and m.brand_pack <> 'N.A'
group by m.brand_pack, left(v.mes,4)
order by m.brand_pack, anio
