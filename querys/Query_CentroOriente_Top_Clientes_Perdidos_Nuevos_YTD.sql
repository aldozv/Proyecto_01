/* Top 5 clientes por GV que dejaron de comprar (alta antes de 2025, compraron Ene-Oct 2025 y no Ene-Oct 2026) y top 5
   clientes nuevos (alta 2025-2026) que mas compran en Ene-Oct 2026. Beer+Rtds, cartera de Centro Oriente (dm_cliente vigente).
   Sirve para detectar recodificaciones (mismo grupo con codigo/RUC nuevo, ej. Bonanza en Iquitos) y rotacion de cuentas grandes. */
WITH cli AS (
  SELECT c.cliente_id, REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv, c.nombre, c.estado, YEAR(c.fecha_alta) AS anio_alta,
    c.unidad_negocio_revenue_volumen_meta AS canal, c.subcanal, c.centro_id
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  WHERE c.direccion = 'PE Dir Centro Orient' AND LEN(c.cliente_id) = 8
    AND c.unidad_negocio NOT LIKE 'DAs Sellout' AND c.unidad_negocio NOT LIKE 'Consumidor'

),
v AS (
  SELECT dv.cliente_id,
    SUM(CASE WHEN dv.mes LIKE '2025%' THEN dv.hl ELSE 0 END) AS hl_25,
    SUM(CASE WHEN dv.mes LIKE '2026%' THEN dv.hl ELSE 0 END) AS hl_26,
    MAX(CASE WHEN dv.hl > 0 THEN dv.mes END) AS ult_mes
  FROM slv_maz_dataexperience_peru_dm.dm_venta dv
  WHERE dv.mes IN ('202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                   '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND dv.indicadores_comerciales = 1 AND dv.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY dv.cliente_id
),
x AS (
  SELECT c.*, v.hl_25, v.hl_26, v.ult_mes,
    CASE WHEN c.anio_alta < 2025 AND v.hl_25 > 0 AND v.hl_26 <= 0 THEN 'perdido'
         WHEN c.anio_alta >= 2025 AND v.hl_26 > 0 THEN 'nuevo' END AS tipo,
    ROW_NUMBER() OVER (PARTITION BY c.gv, CASE WHEN c.anio_alta < 2025 AND v.hl_25 > 0 AND v.hl_26 <= 0 THEN 'perdido' WHEN c.anio_alta >= 2025 AND v.hl_26 > 0 THEN 'nuevo' END
                       ORDER BY CASE WHEN c.anio_alta < 2025 THEN v.hl_25 ELSE v.hl_26 END DESC) AS rk
  FROM cli c JOIN v ON c.cliente_id = v.cliente_id
)
SELECT gv, tipo, rk, cliente_id, nombre, estado, anio_alta, canal, subcanal, centro_id, ROUND(hl_25) AS hl25, ROUND(hl_26) AS hl26, ult_mes
FROM x WHERE tipo IS NOT NULL AND rk <= 5
ORDER BY gv, tipo, rk
LIMIT 60
