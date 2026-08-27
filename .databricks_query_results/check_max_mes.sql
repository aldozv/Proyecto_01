SELECT max(dm_venta.mes) as mes_max
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta
WHERE dm_venta.mes >= '202601'
LIMIT 1
