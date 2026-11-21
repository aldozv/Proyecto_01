-- Volumen (HL) Beer+Rtds YTD Ene-Oct 2022 por gerencia x canal x marca, Direccion Centro Oriente.
-- Base 2022 para los puentes YTD 22 -> 26. Gerencia y canal vigentes (dm_cliente), High End dentro de DSD ON,
-- marca desde dm_material (dm_venta.marca viene nulo en historico).
SELECT
  c.gerencia,
  CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END AS canal,
  COALESCE(m.marca, 'Sin marca') AS marca,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
  ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202201' AND '202210'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY c.gerencia,
  CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
       ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END,
  COALESCE(m.marca, 'Sin marca')
ORDER BY 1, 2, 3
