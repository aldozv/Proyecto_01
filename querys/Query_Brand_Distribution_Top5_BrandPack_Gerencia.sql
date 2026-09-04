-- Top 5 marca x pack por gerencia (ranking por volumen total ene'24-ago'26), con su serie mensual
-- completa. Alimenta las lineas de producto del artifact "Evolución de Brand Distribution" cuando
-- se selecciona Total Direccion o una gerencia (linea Total + top 5 productos de esa gerencia).
with base as (
    select
        v.gerencia,
        m.brand_pack,
        v.mes,
        sum(case
            when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
            when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
            when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
            else 0
        end) as bd
    from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
    left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
    where v.direccion ilike '%PE Dir Centro Orient%'
    and v.fecha_venta between '2024-01-01' and '2026-08-31'
    and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
    and m.brand_pack not in ('N.A', 'Corona Tropical 355 CAN', 'P.Trujillo 620 RB', 'P.Trujillo 473 CAN',
                              'P.Trujillo 355 CAN', 'Arequipeña 620 RB', 'Arequipeña 473 CAN',
                              'Kauffmann 355 CAN', 'Pacífico Clara 355 CAN', 'Barbarian 269 CAN')
    group by v.gerencia, m.brand_pack, v.mes
),
totals as (
    select gerencia, brand_pack, sum(bd) as total_bd
    from base group by gerencia, brand_pack
),
ranked as (
    select gerencia, brand_pack, total_bd,
        row_number() over (partition by gerencia order by total_bd desc) as rn
    from totals
)
select b.gerencia, r.rn, b.brand_pack, b.mes, b.bd
from base b
join ranked r on r.gerencia = b.gerencia and r.brand_pack = b.brand_pack
where r.rn <= 5
order by b.gerencia, r.rn, b.mes
