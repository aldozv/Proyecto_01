-- Ejemplo real de un cliente donde direccion/gerencia (venta actual), direccion_historia/
-- gerencia_historia y direccion_venta/gerencia_venta difieren entre si, en 202501.
SELECT
  a.cliente_id,
  c.nombre AS nombre_cliente,
  a.mes,
  a.direccion,
  a.gerencia,
  a.direccion_historia,
  a.gerencia_historia,
  a.direccion_venta,
  a.gerencia_venta,
  COUNT(*) AS filas
FROM slv_maz_dataexperience_peru_dm.dm_venta a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente c
  ON a.cliente_id = c.cliente_id
WHERE a.mes = '202501'
  AND a.indicadores_comerciales = 1
  AND a.direccion <> a.direccion_historia
  AND a.direccion <> a.direccion_venta
GROUP BY a.cliente_id, c.nombre, a.mes, a.direccion, a.gerencia, a.direccion_historia,
  a.gerencia_historia, a.direccion_venta, a.gerencia_venta
LIMIT 5
