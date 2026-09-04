-- Brand Distribution: matriz gerencia x mes, ene'24 a ago'26, Direccion Centro Oriente
-- Alcance: Cervezas + Licores + Ready To Drink. Total oficial por gerencia (ver CLAUDE.md):
--   Pucall Hco y Huancay Ch -> solo SELLIN
--   Iquitos y Tarapoto      -> SELLIN + SELLOUT
--   DA Jun Puc              -> solo SELLOUT
-- Fuente de datos del artifact "Evolución de Brand Distribution" (grafico interactivo por
-- gerencia/CD/marca x pack) -- reejecutar y volver a pegar los arrays si se necesita refrescar.
select
    v.gerencia,
    v.mes,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as brand_distribution_oficial
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-08-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.gerencia, v.mes
order by v.gerencia, v.mes
