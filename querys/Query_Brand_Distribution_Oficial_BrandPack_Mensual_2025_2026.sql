-- Brand Distribution oficial por brand_pack x mes, Ene'25-Oct'26, Centro Oriente, Beer+Rtds (regla oficial por GV). v6: SKUs que mas aportan.
select m.brand_pack, v.mes,
  sum(case
    when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
    when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
    when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
    else 0 end) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2025-01-01' and '2026-10-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by m.brand_pack, v.mes
order by m.brand_pack, v.mes
limit 5000
