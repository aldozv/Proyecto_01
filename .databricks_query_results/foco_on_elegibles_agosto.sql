SELECT
  e.listado,
  count(distinct a.cliente_id) AS clientes_elegibles,
  count(distinct a.material_id) AS skus_en_promo
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
  AND a.mes = 202608
  AND a.estado = 'R'
GROUP BY e.listado
