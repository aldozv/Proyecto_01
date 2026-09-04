-- Performance de la promo "Verano Amazonico" (BEER = Cervezas+Licores), enero-agosto 2026,
-- resumen por gerencia. Direccion Centro Oriente.
-- Fuente: dm_venta.descuento/hl/nr (real facturado). Campana identificada via
-- dm_promocion.abreviacion_sap -> revenue_maestro_etiquetas.listado = 'Verano Amazonico'.

WITH venta AS (
    SELECT a.gerencia, a.promocion_id, a.descuento, a.hl, a.nr, a.cliente_id
    FROM slv_maz_dataexperience_peru_dm.dm_venta a
    LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material b ON b.material_id = a.material_id
    WHERE
        a.direccion = 'PE Dir Centro Orient'
        AND a.mes BETWEEN 202601 AND 202608
        AND a.agrupador = 'Venta'
        AND a.indicadores_comerciales = 1
        AND b.estratificacion IN ('Cervezas', 'Licores')
        AND a.promocion_id IS NOT NULL
),
promo_ids AS (SELECT DISTINCT promocion_id FROM venta),
promo_map AS (
    SELECT promocion_id, MIN(abreviacion_sap) AS abreviacion_sap
    FROM slv_maz_dataexperience_peru_dm.dm_promocion
    WHERE
        desde <= '2026-08-31' AND hasta >= '2026-01-01'
        AND promocion_id IN (SELECT promocion_id FROM promo_ids)
    GROUP BY promocion_id
),
etiquetas AS (
    SELECT abreviacion_sap, listado FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
    WHERE proyecto = 'promos'
),
verano AS (
    SELECT v.*
    FROM venta v
    JOIN promo_map pm ON pm.promocion_id = v.promocion_id
    JOIN etiquetas e ON e.abreviacion_sap = pm.abreviacion_sap
    WHERE e.listado = 'Verano Amazonico'
)
SELECT
    gerencia,
    ROUND(SUM(hl), 2) AS hl,
    ROUND(-SUM(descuento), 2) AS dscto_soles,
    ROUND(-SUM(descuento) / NULLIF(SUM(hl), 0), 2) AS dscto_x_hl,
    ROUND(SUM(nr), 2) AS nr,
    COUNT(DISTINCT cliente_id) AS clientes_distintos,
    0 AS es_total
FROM verano
GROUP BY gerencia

UNION ALL

SELECT
    'TOTAL' AS gerencia,
    ROUND(SUM(hl), 2) AS hl,
    ROUND(-SUM(descuento), 2) AS dscto_soles,
    ROUND(-SUM(descuento) / NULLIF(SUM(hl), 0), 2) AS dscto_x_hl,
    ROUND(SUM(nr), 2) AS nr,
    COUNT(DISTINCT cliente_id) AS clientes_distintos,
    1 AS es_total
FROM verano

ORDER BY es_total ASC, hl DESC
