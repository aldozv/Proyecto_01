-- Deep dive BD Lima: BD SELLIN Beer+Rtds y POCs compradores por gerencia vigente x canal vigente x mes, Ene'23-Set'26 (oficial)
select c.sales_region_name as gerencia, coalesce(c.business_unit_target_volume,'Sin clasificar') as canal, v.mes,
  sum(v.flag_brand_distro) as bd, count(distinct case when v.flag_brand_distro > 0 then v.cliente_id end) as pocs
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = v.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product d on d.product_short_code = v.material_id
where v.fecha_venta between '2023-01-01' and '2026-09-30' and v.tipo = 'SELLIN' and c.sales_area_name = 'PE Dir Lima' and c.sales_region_name like 'PE Ger P1%' and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3
limit 5000
