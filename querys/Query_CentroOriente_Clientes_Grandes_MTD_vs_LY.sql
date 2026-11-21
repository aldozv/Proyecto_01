-- Clientes de canales concentrados (DAs, Mayoristas, Eventos, KKAA, High End) MTD 1-18 Oct 2026 vs 2025, Beer+Rtds.
-- Identifica que clientes puntuales explican el gap en estos canales.
SELECT c.gerencia, c.centro_id, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal,
  v.cliente_id, MAX(c.nombre) AS nombre,
  SUM(CASE WHEN v.mes='202510' THEN v.hl ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN v.mes='202610' THEN v.hl ELSE 0 END) AS hl_cy
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes IN ('202510','202610')
  AND (v.fecha_venta BETWEEN '2025-10-01' AND '2025-10-18' OR v.fecha_venta BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.direccion = 'PE Dir Centro Orient' AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  AND c.unidad_negocio_revenue_volumen_meta NOT IN ('DSD OFF','DSD ON')
GROUP BY 1,2,3,4
HAVING ABS(SUM(CASE WHEN v.mes='202610' THEN v.hl ELSE 0 END) - SUM(CASE WHEN v.mes='202510' THEN v.hl ELSE 0 END)) >= 100
ORDER BY ABS(SUM(CASE WHEN v.mes='202610' THEN v.hl ELSE 0 END) - SUM(CASE WHEN v.mes='202510' THEN v.hl ELSE 0 END)) DESC
LIMIT 60
