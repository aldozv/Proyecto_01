select count(*) as total_filas
from (
	select
		a.direccion,
		a.gerencia,
		c.centro,
		c.unidad_negocio_revenue_volumen_meta as UN_META,
		a.unidad_negocio_revenue_1yp as UN_1YP,
		a.agrupador,
		a.estratificacion,
		d.marca,
		d.marca_gpa,
		d.pack,
		a.material_id,
		b.nombre as nombre_sku,
		d.`Agrupador (Sku)`,
		d.`Agrupador (Tipo 2.0)`,
		d.kpi_premium as premium,
		d.ms_ss as multipack,
		date_format(a.fecha_venta,'yyyy') as ano,
		date_format(a.fecha_venta,'MM') as mes
	from slv_maz_dataexperience_peru_dm.dm_venta a
	left join slv_maz_dataexperience_peru_dm.dm_material b on b.material_id = a.material_id
	left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
	left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku
	where a.fecha_venta between '2025-01-01' and '2026-12-31'
	and a.direccion = 'PE Dir Centro Orient'
	and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
	and a.indicadores_comerciales= 1
	group by all
) t
