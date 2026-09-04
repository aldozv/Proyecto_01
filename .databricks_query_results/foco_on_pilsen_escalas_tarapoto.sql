SELECT
  a.tipo_mecanica AS escala_codigo,
  a.escala,
  a.descripcion,
  a.bajo,
  a.alto,
  min(a.desde) AS vigencia_desde,
  max(a.hasta) AS vigencia_hasta,
  count(distinct a.cliente_id) AS clientes_en_escala
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
INNER JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = a.cliente_id
WHERE e.listado = 'Foco ON Oriente'
  AND a.material_id = '3302'
  AND a.mes = 202608
  AND c.gerencia = 'PE Ger P4 Tarapoto'
GROUP BY a.tipo_mecanica, a.escala, a.descripcion, a.bajo, a.alto
ORDER BY a.tipo_mecanica, vigencia_desde DESC
