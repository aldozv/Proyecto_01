-- AGREGAR PORTE (agregado por anomes, sin detalle de documento/fecha/semana)

select
a.cliente_id as codigo,
c.nombre,
a.direccion,
c.gerencia,
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
a.mes as anomes,

--Facturacion Final: GSI + Dscto_Caja*CF + Porte_Caja*CF
--NR: GSI + EXCISE + DSCTO_TOTAL

sum(a.hl) as HL,
sum(a.caja_fisica) as CF,
sum(a.caja_equivalente) as CE,
sum(a.gsi) as GSI,
sum(a.excise) as EXCISE,
sum(a.descuento) as DSCTO,
sum(a.nr) as NR,
sum(a.gsi)/sum(a.caja_fisica) as PTR_Base,
sum(a.descuento)/sum(a.caja_fisica) as Dscto_CF,
sum(a.gsi)/sum(a.caja_fisica)+sum(a.descuento)/sum(a.caja_fisica) as PTR_Final

from slv_maz_dataexperience_peru_dm.dm_venta a
left join slv_maz_dataexperience_peru_dm.dm_material b on b.material_id = a.material_id
left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku

where a.fecha_venta between '2025-01-01' and '2026-12-31'
and a.direccion = 'PE Dir Centro Orient'
and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
and a.indicadores_comerciales = 1
group by all
