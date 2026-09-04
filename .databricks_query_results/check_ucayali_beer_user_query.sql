select
	a.cliente_id as codigo, 
	c.nombre,
	c.direccion,
	c.gerencia,
	c.centro,
    c.unidad_negocio_revenue_volumen_meta as UN_META,
	a.unidad_negocio_revenue_1yp as UN_1YP,
	a.fecha_venta,
	date_format(a.fecha_venta,'yyyy') as ano,
	date_format(a.fecha_venta,'MM') as mes, 
	date_format(a.fecha_venta,'dd') as dia,
	sum(a.hl) as HL
	from slv_maz_dataexperience_peru_dm.dm_venta a
	left join slv_maz_dataexperience_peru_dm.dm_material b on b.material_id = a.material_id
	left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
	left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku
	where a.fecha_venta between '2026-01-01' and '2026-08-31'
	and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
	and a.cliente_id IN ('13836158')
	and a.indicadores_comerciales= 1
	group by all
