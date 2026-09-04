WITH promos AS (
  SELECT DISTINCT a.promocion_id, a.cliente_id, a.material_id, e.listado
  FROM slv_maz_dataexperience_peru_dm.dm_promocion a
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
  WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
    AND a.mes = 202608
)
SELECT
  COALESCE(p.listado, 'Resto de cartera') AS segmento,
  count(distinct v.cliente_id) AS clientes,
  count(distinct v.material_id) AS skus,
  sum(v.hl) AS HL,
  sum(v.caja_fisica) AS CF,
  sum(v.gsi) AS GSI,
  sum(v.descuento) AS DSCTO,
  sum(v.nr) AS NR
FROM slv_maz_dataexperience_peru_dm.dm_venta v
LEFT JOIN promos p
  ON v.promocion_id = p.promocion_id AND v.cliente_id = p.cliente_id AND v.material_id = p.material_id
WHERE v.direccion = 'PE Dir Centro Orient'
  AND v.mes = 202608
  AND v.agrupador = 'Venta'
  AND v.indicadores_comerciales = 1
GROUP BY COALESCE(p.listado, 'Resto de cartera')
ORDER BY HL DESC
