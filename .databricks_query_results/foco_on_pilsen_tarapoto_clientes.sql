SELECT DISTINCT
  a.cliente_id,
  a.tipo_mecanica AS escala,
  a.bajo,
  a.alto,
  a.desde,
  a.hasta
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
INNER JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = a.cliente_id
WHERE e.listado = 'Foco ON Oriente'
  AND a.material_id = '3302'
  AND a.mes = 202608
  AND c.gerencia = 'PE Ger P4 Tarapoto'
ORDER BY escala, a.cliente_id
LIMIT 500
