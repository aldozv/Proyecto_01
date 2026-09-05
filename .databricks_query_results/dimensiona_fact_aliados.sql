WITH aliados AS (
  SELECT DISTINCT cliente_id
  FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados
  WHERE mes = '202608'
)
SELECT
  COUNT(*) AS filas,
  COUNT(DISTINCT v.cliente_id) AS clientes,
  COUNT(DISTINCT v.mes) AS meses,
  COUNT(DISTINCT r.`Agrupador (Sku)`) AS brandpacks
FROM slv_maz_dataexperience_peru_dm.dm_venta v
JOIN slv_maz_dataexperience_peru_dm.dm_cliente c
  ON c.cliente_id = v.cliente_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON r.sku = v.material_id
WHERE v.mes >= '202501'
  AND v.agrupador = 'Venta'
  AND v.estado_venta = '1'
  AND v.material_id <> '22868'
  AND v.estratificacion IN ('Cervezas','Licores')
  AND c.direccion = 'PE Dir Centro Orient'
  AND c.gerencia <> 'PE Ger P4 DA Jun Puc'
  AND v.cliente_id IN (SELECT cliente_id FROM aliados)
LIMIT 10;
