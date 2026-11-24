-- Brand Distribution MTD (fecha_venta 1-21 Oct) 2026 vs 2025, Beer+Rtds, Direccion Lima.
-- Lima solo reporta SELLIN (SELLOUT = 0), total oficial = SELLIN.
-- Grano: gerencia (de la tabla BD) x brand_pack x anio, + POCs con >=1 flag.
select
    v.gerencia,
    m.brand_pack,
    m.estratificacion,
    year(v.fecha_venta) as anio,
    sum(v.flag_brand_distro) as bd,
    count(distinct case when v.flag_brand_distro > 0 then v.cliente_id end) as pocs
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Lima%'
and v.tipo ilike '%SELLIN%'
and v.mes in ('202510','202610')
and (v.fecha_venta between '2025-10-01' and '2025-10-21' or v.fecha_venta between '2026-10-01' and '2026-10-21')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and m.brand_pack not in ('N.A', 'Corona Tropical 355 CAN', 'P.Trujillo 620 RB', 'P.Trujillo 473 CAN',
                          'P.Trujillo 355 CAN', 'Arequipeña 620 RB', 'Arequipeña 473 CAN',
                          'Kauffmann 355 CAN', 'Pacífico Clara 355 CAN', 'Barbarian 269 CAN')
group by 1,2,3,4
limit 5000
