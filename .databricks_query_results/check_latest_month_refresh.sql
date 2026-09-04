SELECT max(mes) AS max_mes, count(*) AS filas
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta
WHERE mes >= '202601'
LIMIT 1
