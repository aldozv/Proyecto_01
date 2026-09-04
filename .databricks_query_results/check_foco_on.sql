SELECT
  proyecto,
  listado,
  count(*) as n_registros,
  count(distinct abreviacion_sap) as n_abreviaciones,
  min(created_at) as primer_registro,
  max(created_at) as ultimo_registro
FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas
WHERE listado ILIKE '%foco%'
GROUP BY proyecto, listado
ORDER BY proyecto, listado
