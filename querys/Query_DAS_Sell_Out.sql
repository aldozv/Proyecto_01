SELECT
  f.mes,
  day(f.fecha_venta) as dia,
  'SELL OUT' as tipo_venta, 
  d.grupo,
  f.direccion,
  f.gerencia,
  case
  	when f.razon_social = 'Distribuidora Maximo Sanchez S.R.L.' then 'INVERSIONES DMS S.R.L.'
  	when f.razon_social = 'Central Peru S.A.' then 'P & A Logistic S.A.C. - Huancayo'
  	when f.razon_social = 'Bustamante Medina, Jose Edilberto' then 'P & A Logistic S.A.C. Piura'
  	when f.razon_social = 'Distribuidora Wong Ruiz S.A.C' then 'P & A Logistic S.A.C. Piura'
  	when f.razon_social = 'Transportes Hermanos Linares S.A.C' then 'Distribuidora Vacri'
  	when f.razon_social = 'Direor S.A.C.' then 'Dismar Cinco Sociedad De Responsabilidad Limitada Huánuco'
  else f.razon_social
  end as razon_social,
--   e.sku as material_id,
sum(hl) as hl
FROM slv_maz_dataexperience_peru_dm.dm_das_venta f
    left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c
      on f.cliente_id = c.cliente_id
    left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_material_agrupacion d
      on d.material_id = f.material_id
      and d.mes = date_format(current_date,'yyyyMM')
    left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku e
      on e.sku = f.material_id
where
  f.mes = '202609'
  and day(f.fecha_venta) < date_format(current_date,'dd')
  and d.grupo_id in ('01','18','09','90','53')
  and f.indicadores_comerciales = 1
group by all
order by all