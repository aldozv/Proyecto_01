-- Corona Cero (marca 'Corona Cero', 355 NRB) por gerencia x CD x mes, 2025-2026 (HL).
-- Gerencia/CD de dm_cliente (regla vigente CLAUDE.md 2026-09-04). Alcance: Direccion Centro Oriente.
SELECT
  c.gerencia,
  c.centro,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202501' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.marca = 'Corona Cero'
GROUP BY c.gerencia, c.centro, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY c.gerencia, c.centro, anio, mes_num
