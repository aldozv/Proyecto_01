-- Promos y combos vigentes en algun momento del mes indicado (por defecto setiembre 2026),
-- para clientes de Direccion Centro Oriente.
-- Vigencia: desde <= fin_de_mes AND hasta >= inicio_de_mes (overlap con el mes, no solo "activa hoy").
-- Ajustar las fechas del rango segun el mes que se quiera consultar.
--
-- clientes_inscritos = clientes distintos con al menos una definicion (combo_id/promocion_id)
-- vigente en el mes -- viene de dm_promocion/dm_combo (inscripcion/elegibilidad), NO de venta real.

WITH clientes_co AS (
    SELECT cliente_id
    FROM slv_maz_dataexperience_peru_dm.dm_cliente
    WHERE direccion = 'PE Dir Centro Orient'
),
promos_activas AS (
    SELECT DISTINCT
        p.promocion_id,
        p.cliente_id,
        p.abreviacion_sap,
        p.descripcion,
        p.tipo_mecanica,
        p.desde,
        p.hasta
    FROM slv_maz_dataexperience_peru_dm.dm_promocion p
    JOIN clientes_co c ON c.cliente_id = p.cliente_id
    WHERE p.desde <= '2026-09-30' AND p.hasta >= '2026-09-01'
),
combos_activos AS (
    SELECT DISTINCT
        co.combo_id,
        co.cliente_id,
        co.abreviacion_sap,
        co.descripcion_corta AS descripcion,
        co.tipo_mecanica,
        co.desde,
        co.hasta
    FROM slv_maz_dataexperience_peru_dm.dm_combo co
    JOIN clientes_co c ON c.cliente_id = co.cliente_id
    WHERE co.desde <= '2026-09-30' AND co.hasta >= '2026-09-01'
),
etiquetas_promos AS (
    SELECT abreviacion_sap, listado FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
    WHERE proyecto = 'promos'
),
etiquetas_combos AS (
    SELECT abreviacion_sap, listado FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
    WHERE proyecto = 'combos_promos'
)
-- Solo campanas con nombre de campana reconocido (listado mapeado en revenue_maestro_etiquetas).
-- El resto (combos/promos ad-hoc sin abreviacion_sap o sin mapear -- ver hallazgo previo sobre
-- el bucket OTROS/NULL) se resume en una sola fila "Otras (sin campana con nombre)".
SELECT
    'Promo' AS tipo,
    ep.listado AS nombre,
    pa.tipo_mecanica,
    MIN(pa.desde) AS desde,
    MAX(pa.hasta) AS hasta,
    COUNT(DISTINCT pa.promocion_id) AS cant_promociones,
    COUNT(DISTINCT pa.cliente_id) AS clientes_inscritos
FROM promos_activas pa
JOIN etiquetas_promos ep ON ep.abreviacion_sap = pa.abreviacion_sap
GROUP BY ep.listado, pa.tipo_mecanica

UNION ALL

SELECT
    'Promo' AS tipo,
    'Otras (sin campana con nombre)' AS nombre,
    NULL AS tipo_mecanica,
    MIN(pa.desde) AS desde,
    MAX(pa.hasta) AS hasta,
    COUNT(DISTINCT pa.promocion_id) AS cant_promociones,
    COUNT(DISTINCT pa.cliente_id) AS clientes_inscritos
FROM promos_activas pa
LEFT JOIN etiquetas_promos ep ON ep.abreviacion_sap = pa.abreviacion_sap
WHERE ep.listado IS NULL

UNION ALL

SELECT
    'Combo' AS tipo,
    ec.listado AS nombre,
    ca.tipo_mecanica,
    MIN(ca.desde) AS desde,
    MAX(ca.hasta) AS hasta,
    COUNT(DISTINCT ca.combo_id) AS cant_promociones,
    COUNT(DISTINCT ca.cliente_id) AS clientes_inscritos
FROM combos_activos ca
JOIN etiquetas_combos ec ON ec.abreviacion_sap = ca.abreviacion_sap
GROUP BY ec.listado, ca.tipo_mecanica

UNION ALL

SELECT
    'Combo' AS tipo,
    'Otros (sin campana con nombre)' AS nombre,
    NULL AS tipo_mecanica,
    MIN(ca.desde) AS desde,
    MAX(ca.hasta) AS hasta,
    COUNT(DISTINCT ca.combo_id) AS cant_promociones,
    COUNT(DISTINCT ca.cliente_id) AS clientes_inscritos
FROM combos_activos ca
LEFT JOIN etiquetas_combos ec ON ec.abreviacion_sap = ca.abreviacion_sap
WHERE ec.listado IS NULL

ORDER BY tipo, nombre
