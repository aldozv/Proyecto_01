SELECT
  a.mes,
  c.gerencia,
  COUNT(DISTINCT a.cliente_id) AS clientes,
  COUNT(DISTINCT c.supervisor) AS supervisores,
  COUNT(DISTINCT c.zona_pem) AS zonas_pem
FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados a
JOIN slv_maz_dataexperience_peru_dm.dm_cliente c
  ON c.cliente_id = a.cliente_id
WHERE a.mes >= '202501'
  AND c.direccion = 'PE Dir Centro Orient'
GROUP BY a.mes, c.gerencia
ORDER BY a.mes DESC, c.gerencia
LIMIT 200;
