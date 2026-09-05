SELECT
  MAX(mes) AS mes_max,
  COUNT(DISTINCT cliente_id) AS clientes_distintos
FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados
WHERE mes >= '202501'
LIMIT 10;
