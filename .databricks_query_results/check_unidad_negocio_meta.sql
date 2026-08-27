SELECT unidad_negocio_revenue_volumen_meta, canal, count(*) as filas
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente
WHERE gerencia = 'PE Ger P4 Pucall Hco'
  AND mes = '202607'
GROUP BY unidad_negocio_revenue_volumen_meta, canal
ORDER BY filas DESC
