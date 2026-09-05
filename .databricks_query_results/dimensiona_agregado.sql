WITH aliados AS (
  SELECT DISTINCT cliente_id
  FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados
  WHERE mes = '202608'
),
agg AS (
  SELECT
    v.cliente_id,
    v.mes,
    IFNULL(r.`Agrupador (Sku)`, 'Sin mapear') AS brandpack,
    IFNULL(r.kpi_premium, 'No') AS kpi_premium,
    SUM(v.caja_equivalente) AS ceq
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
  GROUP BY v.cliente_id, v.mes, r.`Agrupador (Sku)`, r.kpi_premium
)
SELECT COUNT(*) AS filas_agregadas, SUM(ceq) AS ceq_total
FROM agg
LIMIT 10;
