-- Verano Amazonico (BEER = Cervezas+Licores), enero-agosto 2026, Direccion Centro Oriente.
-- Grano: gerencia x CD x marca x formato. HL. Base para pivot Gerencia/CD (filas) x Marca (columnas).
-- Confirmado: la promo es 100% formato "CAN XXX" (latas) -- ver Query_Verano_Amazonico_Gerencia.sql.

WITH venta AS (
    SELECT a.gerencia, a.cliente_id, a.material_id, a.promocion_id, a.hl
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
    v.gerencia,
    c.centro,
    d.marca,
    d.pack_xxx AS formato,
    ROUND(SUM(v.hl), 2) AS hl
FROM verano v
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = v.cliente_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d ON d.sku = v.material_id
GROUP BY v.gerencia, c.centro, d.marca, d.pack_xxx
ORDER BY v.gerencia, c.centro, hl DESC
