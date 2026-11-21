-- v8 PR 2026: Sell Out BD de DA Jun Puc atribuible a Centro (distribuidor de Huancayo), mensual Ene'23-Oct'26, Beer+Rtds.
-- Centro = P & A Logistic S.A.C. - Huancayo (dm_das_cliente.sociedad) + POCs sin match en dm_das_cliente
-- (Ene'23-Mar'24: codigos antiguos del distribuidor de Huancayo; desaparecen en Abr'24 cuando entra P & A, mismo tamaño ~10k/mes).
-- Nota: en dm_cliente P & A Logistic Huancayo figura con centro_id BK31, no BK68.
select v.mes,
 sum(case when d.sociedad = 'P & A Logistic S.A.C. - Huancayo' or d.sociedad is null then v.flag_brand_distro else 0 end) as so_centro,
 sum(v.flag_brand_distro) as so_total
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente d on d.cliente_id = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%' and v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%'
and v.fecha_venta between '2023-01-01' and '2026-10-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.mes order by v.mes
limit 100
