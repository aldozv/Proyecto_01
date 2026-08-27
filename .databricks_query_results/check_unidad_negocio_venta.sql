SELECT unidad_negocio_venta, unidad_negocio, unidad_negocio_revenue, count(*) as filas
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta
WHERE dm_venta.mes = '202607'
  AND gerencia = 'PE Ger P4 Pucall Hco'
  AND indicadores_comerciales = 1
GROUP BY unidad_negocio_venta, unidad_negocio, unidad_negocio_revenue
ORDER BY filas DESC
