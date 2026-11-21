-- Overview Lima: Brand Distribution Beer+Rtds por gerencia x tipo x mes, 2023-2026. Lima solo reporta SELLIN. Oct'26 en carga parcial al 20.11. Corrido 2026-11-20.
select v.gerencia, v.tipo, v.mes, sum(v.flag_brand_distro) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Lima%'
and v.fecha_venta between '2023-01-01' and '2026-11-30'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by 1,2,3
order by 1,2,3
limit 5000
