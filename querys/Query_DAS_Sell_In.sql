SELECT
  a.mes,
  a.dia,
  'SELL IN' as tipo_venta,
  c.grupo,
  b.direccion,
  b.gerencia,
  	CASE
  		WHEN b.subcanal = 'Pe Concesionario' THEN 'Pe Concesionario'
      WHEN e.SellOut = 'P & A Logistic S.A.C. Piura - Las Lomas' then 'P & A Logistic S.A.C. Piura'
  		ELSE e.SellOut
  		END AS razon_social,
  -- b.nombre,
--   a.material_id,
  sum(hl) as hl
from
  slv_maz_dataexperience_peru_dm.dm_venta a
    left join slv_maz_dataexperience_peru_dm.dm_cliente b
      on b.cliente_id = a.cliente_id
    left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_material_agrupacion c
      on c.material_id = a.material_id
      and c.mes = date_format(current_date,'yyyyMM')
    LEFT JOIN slv_maz_dataexperience_peru_das.das_nombre_homologacion e
      ON b.nombre = e.SellIn
where
  a.unidad_negocio IN ('DAs')
  and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Agua', 'Gaseosas', 'Maltas')
  and c.grupo_id in ('01','18','09','90','53')
  and a.mes = '202609'
  and a.dia < date_format(current_date,'dd')
  and a.indicadores_comerciales = 1
group by
  all
order by
  all