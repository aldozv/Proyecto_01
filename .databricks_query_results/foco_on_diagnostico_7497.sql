SELECT DISTINCT
  p.cliente_id,
  p.mes,
  p.estado,
  p.desde,
  p.hasta,
  p.escala,
  p.abreviacion_sap
FROM slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN slv_maz_dataexperience_peru_dm.dm_promocion p
  ON v.promocion_id = p.promocion_id AND v.cliente_id = p.cliente_id AND v.material_id = p.material_id
INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  ON e.abreviacion_sap = p.abreviacion_sap AND e.proyecto = 'promos'
WHERE e.listado = 'Foco ON Oriente'
  AND v.material_id = '7497'
  AND v.direccion = 'PE Dir Centro Orient'
  AND v.gerencia = 'PE Ger P4 Tarapoto'
  AND v.mes = 202608
  AND v.agrupador = 'Venta'
  AND v.indicadores_comerciales = 1
ORDER BY p.mes, p.cliente_id
LIMIT 200
