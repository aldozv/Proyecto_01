SELECT
  c.cliente_id, c.nombre, c.direccion, c.gerencia, c.centro,
  c.unidad_negocio_revenue_volumen_meta
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
WHERE c.cliente_id = '13836158'
LIMIT 10
