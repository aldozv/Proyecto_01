-- v7: Brand Distribution oficial (regla por GV) por brand pack agrupado, Ene-Oct 2025 y 2026, Centro Oriente, Beer+Rtds.
-- Golden 620+650 RB = Golden 6XX; Corona 330+355 NRB (sin Corona Cero) = Corona 3XX; Corona Cero aparte. Cuenta cliente x grupo una sola vez.
with b as (
 select v.gerencia, v.tipo, v.cliente_id, v.mes, m.estratificacion,
  case when d.marca in ('Pilsen Fresh','Pilsen Callao Fresh') then 'Pilsen Fresh'
       when d.marca = 'Corona Cero' then 'Corona Cero'
       when d.marca = 'Cusqueña Cero Trigo' then 'Cusqueña Cero'
       when d.marca = 'Flying Fish' then 'Flying Fish'
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand_pack in ('Corona 330 NRB','Corona 355 NRB') then 'Corona 3XX'
       else m.brand_pack end as grp,
  max(v.flag_brand_distro) as fl
 from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
 left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
 left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material d on v.material_id = d.material_id
 where v.direccion ilike '%PE Dir Centro Orient%'
 and (v.fecha_venta between '2025-01-01' and '2025-10-31' or v.fecha_venta between '2026-01-01' and '2026-10-31')
 and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
 group by 1,2,3,4,5,6
)
select grp, estratificacion, mes,
 sum(case when gerencia in ('PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch') and tipo ilike '%SELLIN%' then fl
          when gerencia in ('PE Ger P4 Iquitos','PE Ger P4 Tarapoto') then fl
          when gerencia = 'PE Ger P4 DA Jun Puc' and tipo ilike '%SELLOUT%' then fl else 0 end) as bd
from b group by 1,2,3
limit 3000
