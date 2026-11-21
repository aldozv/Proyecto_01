-- v7 Innovaciones: Brand Distribution oficial (regla por GV) por grupo x SKU x gerencia x mes, Ene-Oct 2025 y 2026
select case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then 'Pilsen Fresh'
            when d.marca in ('Corona Cero','Cusqueña Cero Trigo') then 'Non Alc' else 'Flying Fish' end as grupo,
  d.nombre as sku, v.gerencia, v.mes,
  sum(case when v.gerencia in ('PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
           when v.gerencia in ('PE Ger P4 Iquitos','PE Ger P4 Tarapoto') then v.flag_brand_distro
           when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
inner join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material d on v.material_id = d.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and (v.fecha_venta between '2025-01-01' and '2025-10-31' or v.fecha_venta between '2026-01-01' and '2026-10-31')
and d.marca in ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
group by 1,2,3,4 limit 3000
