-- Lima: Brand Distribution SELLIN Beer+Rtds por gerencia (tabla BD) x canal vigente del cliente (dm_cliente) x anio, Ene-Set 2023-2026.
select v.gerencia, coalesce(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') as canal, substr(v.mes,1,4) as anio, sum(v.flag_brand_distro) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
where v.direccion ilike '%PE Dir Lima%'
and v.tipo ilike '%SELLIN%'
and v.fecha_venta between '2023-01-01' and '2026-09-30'
and cast(substr(v.mes,5,2) as int) <= 9
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and v.gerencia like 'PE Ger P1%'
group by 1,2,3
limit 5000
