SELECT
  e.listado,
  c.unidad_negocio_revenue_volumen_meta,
  count(distinct a.cliente_id) AS clientes
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = a.cliente_id
WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
  AND a.mes = 202608
  AND a.estado = 'R'
GROUP BY e.listado, c.unidad_negocio_revenue_volumen_meta
ORDER BY e.listado, clientes DESC
