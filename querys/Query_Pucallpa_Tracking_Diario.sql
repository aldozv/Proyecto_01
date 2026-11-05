/*VENTA FACTURADA MTD*/
(
SELECT
b.cliente_id as codigo,
b.nombre,
b.gerencia,
b.centro,
CASE
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD OFF') then 'DSD OFF'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD ON','High End') then 'DSD ON'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Mayoristas') then 'WHL'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Eventos') then 'EVE'
WHEN b.unidad_negocio_revenue_volumen_meta in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DAs') then 'DAS'
WHEN unidad_negocio_revenue_volumen_meta is null then 'DSD OFF'
ELSE unidad_negocio_revenue_volumen_meta
END AS canal_grupo,
b.unidad_negocio_revenue_1yp as unidad_negocio_1yp,
b.unidad_negocio_revenue_volumen_meta as unidad_negocio_meta,
b.supervisor,
b.zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.nombre as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.fecha_preventa_flujo1 as fecha_preventa,
a.fecha_venta as fecha_entrega,
sum(a.hl) as HL,
sum(a.caja_equivalente) as CE,
--Caja fisica por SKU: HL x 100000 / (ml por unidad x unidades por caja). Misma formula en los 4 tipos
SUM(a.hl*100000/NULLIF(c.volumen*c.unidades_caja,0)) as CF,
'FACT' as TIPO,
a.numero_venta

FROM slv_maz_dataexperience_peru_dm.dm_venta a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente b on b.cliente_id = a.cliente_id
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material c on c.material_id = a.material_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.material_id

WHERE b.direccion in ('PE Dir Centro Orient')
AND b.gerencia IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
AND a.mes IN ('202611')
AND a.indicadores_comerciales= 1
--Hasta ayer: lo de hoy esta en PLAN
AND a.fecha_venta < CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
GROUP BY ALL
)
UNION ALL

/*PLAN ENTREGA DE HOY*/
(
SELECT
b.cliente_id as codigo,
b.nombre,
b.gerencia,
b.centro,
CASE
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD OFF') then 'DSD OFF'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD ON','High End') then 'DSD ON'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Mayoristas') then 'WHL'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Eventos') then 'EVE'
WHEN b.unidad_negocio_revenue_volumen_meta in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DAs') then 'DAS'
WHEN unidad_negocio_revenue_volumen_meta is null then 'DSD OFF'
ELSE unidad_negocio_revenue_volumen_meta
END AS canal_grupo,
b.unidad_negocio_revenue_1yp as unidad_negocio_1yp,
b.unidad_negocio_revenue_volumen_meta as unidad_negocio_meta,
b.supervisor,
b.zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.nombre as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.FechaCreacionPedido as fecha_creacion,
a.FechaPlan as fecha_entrega,
sum(HLPlaneado) as HL,
sum(HLPlaneado)*13.4408602150538 as CE,
SUM(HLPlaneado*100000/NULLIF(c.volumen*c.unidades_caja,0)) as CF,
'PLAN' as TIPO,
a.NumeroPedido

FROM slv_maz_dataexperience_peru_revenue.revenue_h_pv_planeada a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente b on b.cliente_id = a.codcliente
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material c on c.material_id = a.sku
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.sku

WHERE b.direccion in ('PE Dir Centro Orient')
AND b.gerencia IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
AND a.FechaPlan = CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
--AND a.FechaPlan = DATE_SUB(CAST(GETDATE() AS DATE), 0) /*fecha de hoy*/

GROUP BY ALL
)
UNION ALL

/*PREVENTA D+1*/
(
SELECT
b.cliente_id as codigo,
b.nombre,
b.gerencia,
b.centro,
CASE
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD OFF') then 'DSD OFF'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD ON','High End') then 'DSD ON'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Mayoristas') then 'WHL'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Eventos') then 'EVE'
WHEN b.unidad_negocio_revenue_volumen_meta in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DAs') then 'DAS'
WHEN unidad_negocio_revenue_volumen_meta is null then 'DSD OFF'
ELSE unidad_negocio_revenue_volumen_meta
END AS canal_grupo,
b.unidad_negocio_revenue_1yp as unidad_negocio_1yp,
b.unidad_negocio_revenue_volumen_meta as unidad_negocio_meta,
b.supervisor,
b.zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.nombre as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.FechaCreado as fecha_creacion,
a.FechaEntrega as fecha_entrega,
sum(a.VolumenHl) as HL,
sum(a.VolumenHl)*13.4408602150538 as CE,
SUM(a.VolumenHl*100000/NULLIF(c.volumen*c.unidades_caja,0)) as CF,
'PV D+1' as TIPO,
a.pedido


FROM slv_maz_dataexperience_peru_dm.dm_preventa_flash_actual_fe a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente b on b.cliente_id = a.codcliente
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material c on c.material_id = a.codmaterial
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.codmaterial

WHERE b.direccion in ('PE Dir Centro Orient')
AND b.gerencia IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
--AND a.FechaEntrega = (CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)+1)
--AND a.FechaEntrega = DATE_SUB(CAST(GETDATE() AS DATE)+1, 0) /*fecha de mañana*/
AND b.cliente_id > 10000000
AND a.Anulado = 0
--Solo la siguiente fecha de reparto de la GV (el sabado es el lunes). Las posteriores van en PV FUT
AND a.FechaEntrega = (SELECT MIN(f.FechaEntrega) FROM slv_maz_dataexperience_peru_dm.dm_preventa_flash_actual_fe f JOIN slv_maz_dataexperience_peru_dm.dm_cliente g ON g.cliente_id = f.codcliente WHERE g.gerencia = 'PE Ger P4 Pucall Hco' AND f.FechaEntrega > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE))
GROUP BY ALL
)
UNION ALL

/*PREVENTA FUTURA (SIN PLAN DE HOY NI PREVENTA DE HOY) */
(
SELECT
b.cliente_id as codigo,
b.nombre,
b.gerencia,
b.centro,
CASE
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD OFF') then 'DSD OFF'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DSD ON','High End') then 'DSD ON'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Mayoristas') then 'WHL'
WHEN b.unidad_negocio_revenue_volumen_meta in ('Eventos') then 'EVE'
WHEN b.unidad_negocio_revenue_volumen_meta in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.unidad_negocio_revenue_volumen_meta in ('DAs') then 'DAS'
WHEN unidad_negocio_revenue_volumen_meta is null then 'DSD OFF'
ELSE unidad_negocio_revenue_volumen_meta
END AS canal_grupo,
b.unidad_negocio_revenue_1yp as unidad_negocio_1yp,
b.unidad_negocio_revenue_volumen_meta as unidad_negocio_meta,
b.supervisor,
b.zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.nombre as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.Fecha_Preventa as fecha_creacion,
a.Fecha_Preferente_Entrega as fecha_entrega,
sum(a.hl) as HL,
sum(a.hl)*13.4408602150538 as CE,
SUM(a.hl*100000/NULLIF(c.volumen*c.unidades_caja,0)) as CF,
'PV FUT' as TIPO,
a.numero_preventa

FROM slv_maz_dataexperience_peru_dm.dm_preventa a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente b on b.cliente_id = a.cliente_id
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material c on c.material_id = a.material_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.material_id

WHERE b.direccion in ('PE Dir Centro Orient')
AND b.gerencia IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
AND a.fecha_preferente_entrega > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
AND a.fecha_preferente_entrega < ADD_MONTHS(DATE_FORMAT(CURRENT_DATE(), 'yyyy-MM-1'), 2)
--Excluye solo la fecha que trae PV D+1. IS DISTINCT FROM evita que PV FUT quede vacio si esa fecha es nula
AND a.fecha_preferente_entrega IS DISTINCT FROM (SELECT MIN(f.FechaEntrega) FROM slv_maz_dataexperience_peru_dm.dm_preventa_flash_actual_fe f JOIN slv_maz_dataexperience_peru_dm.dm_cliente g ON g.cliente_id = f.codcliente WHERE g.gerencia = 'PE Ger P4 Pucall Hco' AND f.FechaEntrega > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE))
AND a.flujo = 1
AND b.cliente_id > 10000000
AND a.motivo_anulacion IS NULL
GROUP BY ALL
)
