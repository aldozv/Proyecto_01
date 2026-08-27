SELECT mes, count(*) as filas
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente
GROUP BY mes
ORDER BY mes DESC
LIMIT 20
