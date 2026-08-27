-- Buscar un cliente donde direccion/gerencia (al momento de venta) difiera de
-- direccion_historia/gerencia_historia y/o direccion_venta/gerencia_venta, para armar un ejemplo
-- ilustrativo de las 3 variantes de territorio en dm_venta.
SELECT
  cliente_id,
  mes,
  direccion,
  gerencia,
  direccion_historia,
  gerencia_historia,
  direccion_venta,
  gerencia_venta,
  COUNT(*) AS filas
FROM slv_maz_dataexperience_peru_dm.dm_venta a
WHERE a.mes BETWEEN '202601' AND '202608'
  AND indicadores_comerciales = 1
  AND (
    direccion <> direccion_historia
    OR gerencia <> gerencia_historia
    OR direccion <> direccion_venta
    OR gerencia <> gerencia_venta
  )
GROUP BY cliente_id, mes, direccion, gerencia, direccion_historia, gerencia_historia, direccion_venta, gerencia_venta
LIMIT 20
