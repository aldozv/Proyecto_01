SELECT max(a.mes) AS max_mes
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta a
WHERE a.mes >= '202601'
  AND a.indicadores_comerciales = 1
LIMIT 1
