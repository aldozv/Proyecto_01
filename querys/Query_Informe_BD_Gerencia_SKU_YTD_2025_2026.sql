-- Informe Brand Distribution v1: BD por gerencia x SKU, YTD Ene-Oct 2025 y 2026, Centro Oriente, Beer+Rtds (SELLIN y SELLOUT aparte).
-- Oct'26 va aparte ('2026-10') para escalarlo al oficial por GV (carga parcial en la tabla).
select v.gerencia, v.material_id, d.nombre, case when v.mes = '202610' then '2026-10' else substr(v.mes, 1, 4) end as anio,
  case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then concat('Pilsen Fresh ', m.pack)
       when d.marca = 'Corona Cero' then concat('Corona Cero ', m.pack)
       when d.marca = 'Cusqueña Cero Trigo' then concat('Cusqueña Cero ', m.pack)
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand = 'P.Callao' then concat('Pilsen Callao ', m.pack)
       else m.brand_pack end as bp,
  sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
  sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material d on v.material_id = d.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and (v.fecha_venta between '2025-01-01' and '2025-10-31' or v.fecha_venta between '2026-01-01' and '2026-10-31')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by 1,2,3,4,5
limit 20000
