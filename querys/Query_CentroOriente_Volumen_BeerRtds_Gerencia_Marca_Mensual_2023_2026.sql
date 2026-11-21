-- Volumen (HL) Beer+Rtds por gerencia x marca, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia vigente del cliente (dm_cliente). Marca de dm_material (dm_venta.marca es NULL antes de 2024,
-- ver alerta en BITACORA_TABLAS.md).
SELECT
  v.mes,
  c.gerencia,
  COALESCE(m.marca, 'Sin marca') AS marca,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
  ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, c.gerencia, COALESCE(m.marca, 'Sin marca')
ORDER BY 1, 2, 3
