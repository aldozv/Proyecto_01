-- Informe Brand Distribution v1: BD por gerencia x brand pack agrupado x mes, Ene'23-Oct'26, Centro Oriente, Beer+Rtds.
-- Se trae SELLIN y SELLOUT por separado; la regla oficial por GV se aplica despues (Pucall Hco y Huancay Ch = SELLIN;
-- Iquitos y Tarapoto = SELLIN + SELLOUT; DA Jun Puc = SELLOUT). BD es aditivo a nivel SKU (suma de flag cliente-material-mes).
-- Brand pack: Pilsen Fresh, Corona Cero, Cusqueña Cero y Flying Fish por marca de dm_material + pack; Golden 620/650 RB = Golden 6XX.
select v.gerencia, v.mes, m.estratificacion,
  case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then 'Pilsen Fresh'
       when d.marca = 'Corona Cero' then 'Non Alc'
       when d.marca = 'Cusqueña Cero Trigo' then 'Non Alc'
       when d.marca = 'Flying Fish' then 'Flying Fish'
       when m.brand = 'P.Callao' then 'Pilsen Callao'
       else m.brand end as marca_grp,
  case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then concat('Pilsen Fresh ', m.pack)
       when d.marca = 'Corona Cero' then concat('Corona Cero ', m.pack)
       when d.marca = 'Cusqueña Cero Trigo' then concat('Cusqueña Cero ', m.pack)
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand = 'P.Callao' then concat('Pilsen Callao ', m.pack)
       else m.brand_pack end as bp,
  m.pack,
  sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
  sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material d on v.material_id = d.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2023-01-01' and '2026-10-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by 1,2,3,4,5,6
limit 40000
