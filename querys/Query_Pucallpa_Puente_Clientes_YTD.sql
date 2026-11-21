-- GV Pucallpa: puente de clientes Beer+Rtds YTD Ene-Oct entre pares de anios.
-- Estado: Nuevo (0 a >0), Perdido (>0 a 0), Crece / Cae (activo en ambos).
WITH cy AS (
  SELECT v.cliente_id, c.centro, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal, CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
  WHERE v.mes BETWEEN '202101' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1 AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY 1,2,3,4
), piv AS (
  SELECT cliente_id, centro, canal,
    SUM(CASE WHEN anio=2021 THEN GREATEST(hl,0) ELSE 0 END) y21, SUM(CASE WHEN anio=2022 THEN GREATEST(hl,0) ELSE 0 END) y22,
    SUM(CASE WHEN anio=2023 THEN GREATEST(hl,0) ELSE 0 END) y23, SUM(CASE WHEN anio=2024 THEN GREATEST(hl,0) ELSE 0 END) y24,
    SUM(CASE WHEN anio=2025 THEN GREATEST(hl,0) ELSE 0 END) y25, SUM(CASE WHEN anio=2026 THEN GREATEST(hl,0) ELSE 0 END) y26
  FROM cy GROUP BY 1,2,3
), pares AS (
  SELECT '21-22' par, centro, canal, y21 a, y22 b FROM piv UNION ALL SELECT '22-23', centro, canal, y22, y23 FROM piv
  UNION ALL SELECT '23-24', centro, canal, y23, y24 FROM piv UNION ALL SELECT '24-25', centro, canal, y24, y25 FROM piv
  UNION ALL SELECT '25-26', centro, canal, y25, y26 FROM piv UNION ALL SELECT '21-26', centro, canal, y21, y26 FROM piv
)
SELECT par, centro, canal,
  CASE WHEN a=0 AND b>0 THEN 'Nuevo' WHEN a>0 AND b=0 THEN 'Perdido' WHEN b>=a THEN 'Crece' ELSE 'Cae' END AS estado,
  COUNT(1) AS clientes, SUM(a) AS hl_ini, SUM(b) AS hl_fin
FROM pares WHERE a>0 OR b>0
GROUP BY 1,2,3,4
