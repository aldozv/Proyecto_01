-- Lima SS deep dive Q4: Brand Distribution SELLIN Beer+Rtds por mes x gerencia (tabla BD) x canal vigente x grupo, 2023-01..2026-10
select v.mes, v.gerencia, coalesce(c.business_unit_target_volume,'Sin clasificar') canal,
 case when r.ms_ss is null then 'SIN_MAP' 
      when r.ms_ss='SS' and dm.brand_name='Cristal (Peru)' and r.pack='473 CAN' then 'CR473'
      when r.ms_ss='SS' and dm.brand_name='Budweiser' and r.pack='355 CAN' then 'BUD355'
      when r.ms_ss='SS' then 'SS_OTROS' else 'MS' end grupo,
 sum(v.flag_brand_distro) bd
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm on cast(v.material_id as bigint)=cast(dm.product_short_code as bigint)
left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r on cast(v.material_id as bigint)=cast(r.sku as bigint)
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.cliente_id = c.customer_short_code
where v.direccion ilike '%PE Dir Lima%' and v.tipo ilike '%SELLIN%'
and v.fecha_venta between '2023-01-01' and '2026-10-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by 1,2,3,4
limit 20000
