-- San Juan 620 (marca 'San Juan' + pack '620 RB' de revenue_maestro_sku) por gerencia x CD,
-- YTD (Ene-Set, mes cerrado) 2026 vs 2025, en HL. Gerencia/CD salen de dm_cliente (regla vigente
-- CLAUDE.md 2026-09-04). Alcance: Direccion Centro Oriente (c.direccion).
SELECT
  c.gerencia,
  c.centro,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '202501' AND '202609'
  AND SUBSTR(v.mes,5,2) <= '09'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.marca = 'San Juan'
  AND r.pack = '620 RB'
GROUP BY c.gerencia, c.centro, CAST(SUBSTR(v.mes,1,4) AS INT)
ORDER BY c.gerencia, c.centro, anio
