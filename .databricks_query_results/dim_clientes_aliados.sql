WITH aliados AS (
  SELECT DISTINCT cliente_id
  FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados
  WHERE mes = '202608'
)
SELECT
  c.cliente_id,
  c.nombre,
  c.gerencia,
  c.supervisor,
  c.zona_pem
FROM slv_maz_dataexperience_peru_dm.dm_cliente c
JOIN aliados a ON a.cliente_id = c.cliente_id
WHERE c.direccion = 'PE Dir Centro Orient'
  AND c.gerencia <> 'PE Ger P4 DA Jun Puc'
ORDER BY c.gerencia, c.supervisor, c.nombre
LIMIT 500;
