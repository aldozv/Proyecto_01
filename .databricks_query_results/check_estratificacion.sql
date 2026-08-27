SELECT estratificacion, count(*) as filas, sum(hl) as hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta
WHERE dm_venta.mes = '202607'
  AND gerencia = 'PE Ger P4 Pucall Hco'
  AND indicadores_comerciales = 1
GROUP BY estratificacion
ORDER BY hl DESC
