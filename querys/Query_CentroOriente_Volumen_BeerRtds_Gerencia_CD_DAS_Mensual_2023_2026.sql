-- Volumen (HL) Beer+Rtds por gerencia x CD x flag DAS, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia, CD y canal vigentes del cliente (dm_cliente). DAS = unidad_negocio_revenue_volumen_meta = 'DAs'.
-- Uso: en GV Iquitos y Tarapoto se reporta "DAS - CD X" separado de "CD X" (resto de canales).
SELECT
  v.mes,
  c.gerencia,
  COALESCE(c.centro_id, 'Sin CD') AS centro_id,
  COALESCE(c.centro, 'Sin CD') AS centro,
  CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'DAs' THEN 'DAS' ELSE 'Directo' END AS tipo,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, c.gerencia, COALESCE(c.centro_id, 'Sin CD'), COALESCE(c.centro, 'Sin CD'),
  CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'DAs' THEN 'DAS' ELSE 'Directo' END
ORDER BY 1, 2, 3
