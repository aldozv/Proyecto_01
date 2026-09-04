-- Adherencia a promos/combos + Drops, grano cliente x material x promocion/combo x periodo.
-- Ver documentacion completa en BITACORA_TABLAS.md ->
-- slv_maz_salesdata_salesdatadata_adb.pe_promo_adherenciadiaria
--
-- IMPORTANTE: tabla muy grande (169.6M filas historicas para Centro Oriente sin filtro de
-- periodo; ~4.8M filas por un solo mes). fecha_venta NO sirve para filtrar periodos recientes
-- (dejo de poblarse desde 2025-03-05) -- usar siempre "periodo" (yyyymm).
--
-- Alcance de categoria: Cervezas, Licores, Ready To Drink (misma regla que Brand Distribution,
-- confirmada por el usuario 2026-08-31) -- excluye NABs (Gaseosas/Agua/Maltas) via join a
-- dm_material.estratificacion.
--
-- Definicion de flags (confirmada por el usuario 2026-08-29):
--   flag_venta = compro el SKU especifico de la promo (con o sin descuento aplicado)
--   flag_linea = compro algo de la misma familia/estratificacion del SKU de la promo
--   flag_promo = compro el SKU Y se le aplico efectivamente el descuento/mecanica (adherencia real)

SELECT
    a.proyecto,
    a.listado,
    b.estratificacion,
    COUNT(*) AS filas,
    COUNT(DISTINCT a.cliente_id) AS clientes_distintos,
    SUM(a.flag_venta) AS filas_compro_sku,
    SUM(a.flag_linea) AS filas_compro_familia,
    SUM(a.flag_promo) AS filas_adherencia_real,
    COUNT(DISTINCT CASE WHEN a.flag_venta = 1 THEN a.cliente_id END) AS clientes_compro_sku,
    COUNT(DISTINCT CASE WHEN a.flag_promo = 1 THEN a.cliente_id END) AS clientes_adherencia_real,
    ROUND(SUM(a.flag_promo) / NULLIF(COUNT(*), 0) * 100, 2) AS pct_adherencia_sobre_elegibles,
    ROUND(SUM(a.flag_promo) / NULLIF(SUM(a.flag_venta), 0) * 100, 2) AS pct_adherencia_sobre_compradores,
    SUM(a.hl) AS hl_total,
    SUM(a.dscto) AS dscto_total
FROM brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_promo_adherenciadiaria a
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material b
    ON b.material_id = a.material_id
WHERE
    a.direccion = 'PE Dir Centro Orient'
    AND a.periodo = 202608
    AND b.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
GROUP BY a.proyecto, a.listado, b.estratificacion
ORDER BY a.proyecto, filas DESC
