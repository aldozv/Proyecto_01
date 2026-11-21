-- POCs compradores (Beer+Rtds) y HL MTD 1-18 Oct 2026 vs 2025, por gerencia x CD x canal.
-- Permite separar el gap en "menos clientes comprando" vs "menos volumen por cliente".
SELECT
  c.gerencia, c.centro_id, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal,
  SUBSTR(v.mes,1,4) AS anio,
  COUNT(DISTINCT CASE WHEN v.hl > 0 THEN v.cliente_id END) AS pocs,
  COUNT(DISTINCT CASE WHEN v.hl > 0 THEN CONCAT(v.cliente_id, '|', CAST(v.fecha_venta AS STRING)) END) AS visitas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes IN ('202510','202610')
  AND (v.fecha_venta BETWEEN '2025-10-01' AND '2025-10-18' OR v.fecha_venta BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
