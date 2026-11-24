-- Deep dive BD Lima: BD SELLIN Beer+Rtds por gerencia vigente x SKU, Ene-Oct 2025 y Ene-Set 2026 (oficial)
select c.sales_region_name as gerencia, v.material_id, d.product_name as nombre, substr(v.mes,1,4) as anio, case when d.brand_name in ('Pilsen Fresh','Pilsen Callao Fresh') then concat('Pilsen Fresh ', m.pack)
       when d.brand_name = 'Corona Cero' then concat('Corona Cero ', m.pack)
       when d.brand_name = 'Cusqueña Cero Trigo' then concat('Cusqueña Cero ', m.pack)
       when d.brand_name = 'Flying Fish' then concat('Flying Fish ', m.pack)
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand = 'P.Callao' then concat('Pilsen Callao ', m.pack)
       else m.brand_pack end as bp, sum(v.flag_brand_distro) as bd
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = v.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product d on d.product_short_code = v.material_id
where (v.fecha_venta between '2025-01-01' and '2025-10-31' or v.fecha_venta between '2026-01-01' and '2026-09-30')
  and v.tipo = 'SELLIN' and c.sales_area_name = 'PE Dir Lima' and c.sales_region_name like 'PE Ger P1%' and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3,4,5
limit 30000
