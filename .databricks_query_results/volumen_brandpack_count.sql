-- Dimensionamiento: cuantas filas devolveria el agregado por gerencia/centro/marca/categoria/ano/mes/semana/pack

select count(*) as filas_estimadas
from (
  select
  c.gerencia,
  c.centro,
  d.marca,
  a.estratificacion as categoria,
  substr(a.mes,1,4) as ano,
  substr(a.mes,5,2) as mes,
  a.semana,
  d.pack

  from slv_maz_dataexperience_peru_dm.dm_venta a
  left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
  left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku

  where a.fecha_venta between '2025-01-01' and '2026-12-31'
  and a.direccion = 'PE Dir Centro Orient'
  and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
  and a.indicadores_comerciales = 1
  group by all
) t
