-- Volumen (HL) Beer+Rtds por canal, total Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Canal = dm_cliente.unidad_negocio_revenue_volumen_meta (vigente del cliente).
-- Alcance por c.direccion (regla 2026-09-04). Beer = Cervezas+Licores; Rtds = Ready To Drink.
SELECT
  v.mes,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal,
  CASE WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds' ELSE 'Beer' END AS categoria,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar'),
  CASE WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds' ELSE 'Beer' END
ORDER BY 1, 2, 3
