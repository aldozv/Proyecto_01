-- Volumen (HL) Beer+Rtds por gerencia x CD, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia y CD vigentes del cliente (dm_cliente.gerencia / centro_id / centro).
SELECT
  v.mes,
  c.gerencia,
  COALESCE(c.centro_id, 'Sin CD') AS centro_id,
  COALESCE(c.centro, 'Sin CD') AS centro,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, c.gerencia, COALESCE(c.centro_id, 'Sin CD'), COALESCE(c.centro, 'Sin CD')
ORDER BY 1, 2, 3
