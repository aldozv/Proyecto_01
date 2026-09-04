SELECT
  cliente_id,
  max(CASE WHEN escala = 'SMDES1' THEN bajo END) AS smdes1_bajo,
  max(CASE WHEN escala = 'SMDES1' THEN alto END) AS smdes1_alto,
  max(CASE WHEN escala = 'SMDES2' THEN bajo END) AS smdes2_bajo,
  max(CASE WHEN escala = 'SMDES2' THEN alto END) AS smdes2_alto,
  max(CASE WHEN escala = 'SMDES3' THEN bajo END) AS smdes3_bajo,
  max(CASE WHEN escala = 'SMDES3' THEN alto END) AS smdes3_alto
FROM (
  SELECT DISTINCT
    a.cliente_id,
    a.tipo_mecanica AS escala,
    a.bajo,
    a.alto
  FROM slv_maz_dataexperience_peru_dm.dm_promocion a
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
  INNER JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = a.cliente_id
  WHERE e.listado = 'Foco ON Oriente'
    AND a.material_id = '3302'
    AND a.mes = 202608
    AND c.gerencia = 'PE Ger P4 Tarapoto'
)
GROUP BY cliente_id
ORDER BY cliente_id
LIMIT 500
