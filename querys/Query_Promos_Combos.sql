--Este query te brinda segun la compra por cliente y brandpack con que promo compro y a que descuento y con que combo compro y a que descuento

with
clientes as (select distinct cliente_id from slv_maz_dataexperience_peru_dm.dm_cliente),
--clientes as (select distinct cliente_id from slv_maz_dataexperience_peru_dm.dm_cliente where cliente_id in ('12684867')),

combos as (
SELECT 
    combo_id, 
    cliente_id, 
    material_id, 
    desde, hasta, 
    descripcion_corta, 
    a.tope_cliente_mes,
    mes, 
    descripcion,
    tag,
    a. abreviacion_sap,
    b.listado,
    a.tipo_mecanica,
    a.area_carga, 
   
--estado, 
    tipo_combo, 
    usuario, 
    brand_pack, 
    cantidad, 
    ptr_base_unit, 
    ptr_base_unit_promo, 
    ptr_base_total_promo, 
    descuento_soles_total
FROM slv_maz_dataexperience_peru_dm.dm_combo a
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas b on b.abreviacion_sap = a.abreviacion_sap and b.proyecto = 'combos_promos'
WHERE 
    a.desde >= current_timestamp-interval'5 hours'-interval'2 month'
    and a.cliente_id in (select cliente_id from clientes)
    --and a.abreviacion_sap in ('BOMBCSQ','PCGD473')
    --and usuario NOT IN ('hector.pena-ext@ab-inbev.com', 'cesar.angeles-ext@ab-inbev.com','Ivet.Flores-ext@ab-inbev.com','pe001156@modelo.gmodelo.com.mx','ifloresx@modelo.gmodelo.com.mx')
GROUP BY ALL
),
promos as (
SELECT 
    promocion_id, 
    cliente_id, 
    material_id, 
    desde, 
    hasta,
    a.bajo,
    a.alto,
    mes, 
    descripcion,
    tag,
    a. abreviacion_sap,
    b.listado,
    a.tipo_mecanica,
    a.escala,
    a.periodo_promo
    
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas b on b.abreviacion_sap = a.abreviacion_sap and b.proyecto = 'promos'
WHERE 
    a.desde >= current_timestamp-interval'5 hours'-interval'2 month'
    and a.cliente_id in (select cliente_id from clientes)
    --and a.abreviacion_sap in ('BOMBCSQ','PCGD473')
    --and usuario NOT IN ('hector.pena-ext@ab-inbev.com', 'cesar.angeles-ext@ab-inbev.com','Ivet.Flores-ext@ab-inbev.com','pe001156@modelo.gmodelo.com.mx','ifloresx@modelo.gmodelo.com.mx')
GROUP BY ALL
)






select 
a.mes,
a.semana,
a.cliente_id as codigo, 
c.nombre,
a.direccion,
a.gerencia, 
c.centro,
c.unidad_negocio_revenue_volumen_meta,
a.unidad_negocio_revenue_1yp as UN_1YP,
a.unidad_negocio_revenue as UN, 
a.canal_cliente, 
a.subcanal_cliente, 
a.agrupador,
a.estratificacion,
b.familia,
b.marca,
d.pack_xxx as pack,
d.`Agrupador (Tipo 2.0)` ,
d.kpi_premium as premium,
d.ms_ss as multipack,
d.marca_gpa as marca_gpa,
a.material_id, 
a.promocion_id,
e.listado as listado_p,
a.combo_id,
f.listado as listado_c,
b.nombre as nombre_sku,
a.zona_pem_historia,
a.fecha_preventa_flujo1 as fecha_preventa,
a.fecha_venta,
a.numero_documento_venta,
date_format(a.fecha_venta,'yyyy') as ano,
date_format(a.fecha_venta,'MM') as mes,
date_format(a.fecha_venta,'dd') as dia,   
sum(a.hl) as HL, 
sum(a.caja_fisica) as CF,
sum(a.gsi) as GSI, 
sum(a.excise) as EXCISE,
sum(a.descuento) as DSCTO, 
sum(a.nr) as NR,
sum(a.porte) as PORTE,
sum(a.porte)/sum(a.caja_fisica) as PORTExCAJA,
sum(a.gsi)/sum(a.caja_fisica) as PTR_Base,
sum(a.descuento)/sum(a.caja_fisica) as Dscto_Caja,
sum(a.gsi)/sum(a.caja_fisica)+sum(a.descuento)/sum(a.caja_fisica) as PTR_Final,
sum(a.total) as Fact_Final,
sum(a.descuento)/sum(a.gsi) as DsctoxGSI,
c.supervisor,
c.zona_comisional,
e.tipo_mecanica,
e.escala

from slv_maz_dataexperience_peru_dm.dm_venta a
left join slv_maz_dataexperience_peru_dm.dm_material b on b.material_id=a.material_id
left join slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id =a.cliente_id
left join slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on a.material_id = d.sku
left join promos e on a.promocion_id = e.promocion_id and a.cliente_id = e.cliente_id and a.material_id = e.material_id
left join combos f on a.combo_id = f.combo_id and a.cliente_id = f.cliente_id and a.material_id = f.material_id
where
a.direccion = 'PE Dir Centro Orient'
--and a.estratificacion in ('Cervezas')
and c.unidad_negocio_revenue_volumen_meta in ('DSD OFF','DSD ON')
--and a.gerencia = 'PE Ger P4 Huancay Ch'
--and c.centro in ('CD Tingo María')
--and a.material_id in ('4717','13652','22331','13113','21264','9523','4407','4411','14259','4409','9524','20834','21033','6845')  
--and a.material_id in ('4407','4409') 
--and a.material_id in ('1650','3302','2821','1565','1564')  
and a.mes in (202605)
--and d.`Agrupador (Tipo)`in ('Latas 473')
--and d.`Agrupador (Tipo 2.0)` in ('Latas')
--and d.pack IN ("CAN XXX")
--and d.marca in ('Cusqueña','Golden','P.Callao')
--and a.fecha_venta between '2026-06-17' and '2026-06-22' 
--and a.material_id in ("7497","6843","6842","5259")
--and d.marca in ('Cusqueña','Pilsen','Cristal','San Juan')
--and d.pack in ("620 RB","650 RB","630 RB")
--and a.fecha_preventa_flujo1 between '2026-05-18' and '2026-05-24'
--and a.mes in (202601,202602,202603,202604,202605,202606)
--and e.listado in ('Foco ON Centro','Foco ON Oriente')
--and f.listado in ('Regional Lateros SMD')
--and c.cliente_id IN ('12964103')
AND d.pack_xxx IN ('CAN XXX')
and a.agrupador in ('Venta')
and a.indicadores_comerciales= 1
and a.cliente_id in (select cliente_id from clientes)
group by all