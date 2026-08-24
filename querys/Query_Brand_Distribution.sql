
--query Brand Distribution general--
select 
    -- v.direccion,
    v.gerencia ,
    v.mes,
    v.tipo,
    m.brand,
    m.category_inno,
    m.brand_pack_pop,
    -- v.fecha_venta,
    -- v.cliente_id,
    m.brand_category,
    sum(flag_brand_distro) as sum_brand_distro,
    sum(hl) as sum_hl
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v 
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id 
where v.indicadores_comerciales = 1
-- and v.mes in ('202601','202602','202603','202604','202605','202606','202607','202608')
-- and day(v.fecha_venta) <= 15
and v.fecha_venta between '2025-01-01' and '2026-07-31'
-- and v.gerencia in ('PE Ger P2 Chiclay Ca', 'PE Ger P4 Huancay Ch', 'PE Ger P3 Arequipa', 'PE Ger P3 Tacna')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and v.direccion ilike '%PE Dir Centro Orient%'
and v.tipo ilike '%SELLIN%'
and m.pack ilike '%CAN%'
and m.brand in ('Corona', 'Cusqueña', 'Stella Artois')
and m.category_inno ilike '%Inno%'
group by all