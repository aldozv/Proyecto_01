-- Sell in a los DAS (lo que Backus factura al distribuidor), Centro Oriente, mensual Ene'23-Oct'26, Beer+Rtds.
-- DAS = dm_cliente.unidad_negocio_revenue_volumen_meta = 'DAs'; gerencia/direccion vigentes del maestro.
SELECT v.mes, c.gerencia, c.cliente_id, c.nombre, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND v.indicadores_comerciales = 1
  AND c.direccion = 'PE Dir Centro Orient'
  AND c.unidad_negocio_revenue_volumen_meta = 'DAs'
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY ALL
ORDER BY 1, 2, 4
