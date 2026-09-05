SELECT
  grupo_id,
  grupo,
  mes,
  count(*) as n_materiales
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_material_agrupacion
WHERE grupo_id in ('01','18','09','90','53')
  and mes = date_format(current_date,'yyyyMM')
GROUP BY all
ORDER BY all
