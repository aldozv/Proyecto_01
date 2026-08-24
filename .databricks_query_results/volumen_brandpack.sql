-- AGREGAR PORTE (agregado por gerencia, centro, marca, categoria, ano, mes, semana, pack)

select
c.gerencia,
c.centro,
d.marca,
a.estratificacion as categoria,
substr(a.mes,1,4) as ano,
substr(a.mes,5,2) as mes,
a.semana,
d.pack,

--Facturacion Final: GSI + Dscto_Caja*CF + Porte_Caja*CF
--NR: GSI + EXCISE + DSCTO_TOTAL

sum(a.hl) as HL,
sum(a.caja_fisica) as CF,
sum(a.caja_equivalente) as CE,
sum(a.gsi) as GSI,
sum(a.excise) as EXCISE,
sum(a.descuento) as DSCTO,
sum(a.porte) as PORTE,
sum(a.nr) as NR,
sum(a.gsi)/sum(a.caja_fisica) as PTR_Base,
sum(a.descuento)/sum(a.caja_fisica) as Dscto_CF,
sum(a.porte)/sum(a.caja_fisica) as Porte_CF,
sum(a.gsi)/sum(a.caja_fisica)+sum(a.descuento)/sum(a.caja_fisica) as PTR_Final,
sum(a.gsi)/sum(a.caja_fisica)+sum(a.descuento)/sum(a.caja_fisica)+sum(a.porte)/sum(a.caja_fisica) as Facturacion_Final

from slv_maz_dataexperience_peru_dm.dm_venta a
left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = a.cliente_id
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku

where a.fecha_venta between '2025-01-01' and '2026-12-31'
and a.direccion = 'PE Dir Centro Orient'
and a.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
and a.indicadores_comerciales = 1
group by all
