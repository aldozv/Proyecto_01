-- Ranking de promos y combos de BEER (Cervezas+Licores) por descuento usado, agosto 2026,
-- Direccion Centro Oriente. Fuente: dm_venta.descuento/hl (real facturado), clasificado por
-- promocion_id (Promo) / combo_id (Combo) -- mutuamente excluyentes (validado 2026-09-01).
-- Nombre de campana: revenue_maestro_etiquetas.listado (por abreviacion_sap) con fallback a la
-- descripcion de dm_promocion/dm_combo cuando no esta mapeada.
-- Incluye HL y el ratio Dscto/HL (S/ de descuento por cada HL vendido bajo esa promo/combo) como
-- proxy de "costo por HL" -- mas alto = mas caro sostener esa mecanica por unidad de volumen.

WITH venta_beer AS (
    SELECT a.promocion_id, a.combo_id, a.descuento, a.hl
    FROM slv_maz_dataexperience_peru_dm.dm_venta a
    LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material b ON b.material_id = a.material_id
    WHERE
        a.direccion = 'PE Dir Centro Orient'
        AND a.mes = 202608
        AND a.agrupador = 'Venta'
        AND a.indicadores_comerciales = 1
        AND b.estratificacion IN ('Cervezas', 'Licores')
),
promo_ids AS (SELECT DISTINCT promocion_id FROM venta_beer WHERE promocion_id IS NOT NULL),
combo_ids AS (SELECT DISTINCT combo_id FROM venta_beer WHERE combo_id IS NOT NULL),
promo_map AS (
    SELECT promocion_id, MIN(descripcion) AS descripcion, MIN(abreviacion_sap) AS abreviacion_sap
    FROM slv_maz_dataexperience_peru_dm.dm_promocion
    WHERE
        desde <= '2026-08-31' AND hasta >= '2026-08-01'
        AND promocion_id IN (SELECT promocion_id FROM promo_ids)
    GROUP BY promocion_id
),
combo_map AS (
    SELECT combo_id, MIN(descripcion) AS descripcion, MIN(abreviacion_sap) AS abreviacion_sap
    FROM slv_maz_dataexperience_peru_dm.dm_combo
    WHERE
        desde <= '2026-08-31' AND hasta >= '2026-08-01'
        AND combo_id IN (SELECT combo_id FROM combo_ids)
    GROUP BY combo_id
),
etiquetas_promos AS (
    SELECT abreviacion_sap, listado FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
    WHERE proyecto = 'promos'
),
etiquetas_combos AS (
    SELECT abreviacion_sap, listado FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
    WHERE proyecto = 'combos_promos'
),
detalle AS (
    SELECT
        'Promo' AS tipo,
        COALESCE(ep.listado, pm.descripcion, 'Sin mapear (fuera de ventana desde/hasta)') AS nombre,
        v.descuento,
        v.hl
    FROM venta_beer v
    LEFT JOIN promo_map pm ON pm.promocion_id = v.promocion_id
    LEFT JOIN etiquetas_promos ep ON ep.abreviacion_sap = pm.abreviacion_sap
    WHERE v.promocion_id IS NOT NULL

    UNION ALL

    SELECT
        'Combo' AS tipo,
        COALESCE(ec.listado, cm.descripcion, 'Sin mapear (fuera de ventana desde/hasta)') AS nombre,
        v.descuento,
        v.hl
    FROM venta_beer v
    LEFT JOIN combo_map cm ON cm.combo_id = v.combo_id
    LEFT JOIN etiquetas_combos ec ON ec.abreviacion_sap = cm.abreviacion_sap
    WHERE v.combo_id IS NOT NULL
)
SELECT
    tipo,
    nombre,
    ROUND(SUM(hl), 4) AS hl,
    ROUND(-SUM(descuento), 2) AS dscto_soles,
    ROUND(-SUM(descuento) / NULLIF(SUM(hl), 0), 2) AS dscto_x_hl,
    0 AS es_total
FROM detalle
GROUP BY tipo, nombre

UNION ALL

SELECT
    'TOTAL' AS tipo,
    '' AS nombre,
    ROUND(SUM(hl), 4) AS hl,
    ROUND(-SUM(descuento), 2) AS dscto_soles,
    ROUND(-SUM(descuento) / NULLIF(SUM(hl), 0), 2) AS dscto_x_hl,
    1 AS es_total
FROM detalle

ORDER BY es_total ASC, hl DESC
