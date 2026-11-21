-- Brand Distribution oficial mensual Ene'24-Oct'26 de categorias de expansion (regla oficial por GV), Centro Oriente. Pilsen Fresh = marcas 'Pilsen Fresh' + 'Pilsen Callao Fresh'.
select v.mes,
  case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then 'Pilsen Fresh'
       when d.marca in ('Corona Cero','Cusqueña Cero Trigo') then 'Nolo'
       when d.marca = 'Flying Fish' then 'Flying Fish' end as grupo,
  sum(case
    when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
    when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
    when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
    else 0 end) as bd
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
inner join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material d on v.material_id = d.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-10-31'
and d.marca in ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
group by 1, 2 order by 2, 1
limit 500
