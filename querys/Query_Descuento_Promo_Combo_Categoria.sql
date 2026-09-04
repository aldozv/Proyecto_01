-- Descuento usado (S/) en agosto 2026, Direccion Centro Oriente, categorias Cervezas+Licores
-- agrupadas como "BEER" + RTD, separado por tipo de mecanica: Promo (a.promocion_id no nulo) vs
-- Combo (a.combo_id no nulo).
-- Confirmado: promocion_id y combo_id son mutuamente excluyentes a nivel linea de venta (ninguna
-- fila tiene ambos poblados a la vez, validado 2026-09-01).
-- a.descuento viene negativo (convencion dm_venta) -- ver BITACORA_TABLAS.md.

WITH base AS (
    SELECT
        CASE WHEN b.estratificacion IN ('Cervezas', 'Licores') THEN 'BEER' ELSE 'RTD' END AS categoria,
        a.descuento,
        a.promocion_id,
        a.combo_id
    FROM slv_maz_dataexperience_peru_dm.dm_venta a
    LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material b ON b.material_id = a.material_id
    WHERE
        a.direccion = 'PE Dir Centro Orient'
        AND a.mes = 202608
        AND a.agrupador = 'Venta'
        AND a.indicadores_comerciales = 1
        AND b.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
)
SELECT
    categoria,
    SUM(CASE WHEN promocion_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_promo,
    SUM(CASE WHEN combo_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_combo,
    SUM(CASE WHEN promocion_id IS NOT NULL OR combo_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_total_categoria
FROM base
GROUP BY categoria

UNION ALL

SELECT
    'TOTAL' AS categoria,
    SUM(CASE WHEN promocion_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_promo,
    SUM(CASE WHEN combo_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_combo,
    SUM(CASE WHEN promocion_id IS NOT NULL OR combo_id IS NOT NULL THEN descuento ELSE 0 END) AS dscto_total_categoria
FROM base

ORDER BY categoria
