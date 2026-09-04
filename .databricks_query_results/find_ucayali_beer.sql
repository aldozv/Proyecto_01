SELECT
  c.cliente_id,
  c.nombre,
  c.direccion,
  c.gerencia,
  c.centro,
  c.centro_id,
  c.unidad_negocio_revenue_volumen_meta AS canal
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
WHERE UPPER(c.nombre) LIKE '%UCAYALI%'
LIMIT 50
