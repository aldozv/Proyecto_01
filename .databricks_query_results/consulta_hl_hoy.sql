-- Volumen HL del dia de hoy (2026-08-23), Direccion Centro Oriente
-- Regla vigente: excluir marca San Mateo en categoria Agua (ver CLAUDE.md)

select
a.gerencia,
c.centro,
a.estratificacion as categoria,
sum(a.hl) as HL,
sum(a.caja_fisica) as CF,
sum(a.nr) as NR

from slv_maz_dataexperience_peru_dm.dm_venta a
left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku

where a.fecha_venta = '2026-08-23'
and a.direccion = 'PE Dir Centro Orient'
and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
and a.indicadores_comerciales = 1
and not (a.estratificacion = 'Agua' and d.marca = 'San Mateo')
group by all
order by HL desc
