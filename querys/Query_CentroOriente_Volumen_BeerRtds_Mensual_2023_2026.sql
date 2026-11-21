-- Evolucion volumen (HL) Beer+Rtds, total Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Beer = Cervezas + Licores; Rtds = Ready To Drink. Nabs fuera (regla CLAUDE.md).
-- Alcance por jerarquia vigente: c.direccion de dm_cliente (regla 2026-09-04).
SELECT
  v.mes,
  v.estratificacion,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, v.estratificacion
ORDER BY v.mes, v.estratificacion
