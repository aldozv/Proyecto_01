-- Venta diaria (HL, Beer+Rtds) por gerencia de Centro Oriente, agosto 2026
-- Para cruzar a grosso modo con temperatura diaria por ciudad (analisis exploratorio,
-- no oficial). Usa c.gerencia/c.direccion de dm_cliente por regla vigente del proyecto.
SELECT
  v.fecha_venta,
  c.gerencia,
  SUM(v.hl) AS hl
FROM slv_maz_dataexperience_peru_dm.dm_venta v
JOIN slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes = '202608'
  AND v.indicadores_comerciales = 1
  AND c.direccion = 'PE Dir Centro Orient'
  AND c.gerencia <> 'PE Ger P4 DA Jun Puc'
  AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
GROUP BY v.fecha_venta, c.gerencia
ORDER BY v.fecha_venta, c.gerencia
