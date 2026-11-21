-- POCs compradores (HL neto > 0 en el mes) y volumen Beer+Rtds por gerencia x canal, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Gerencia y canal vigentes del cliente (dm_cliente), High End dentro de DSD ON. Conteos aditivos entre GV/canal (un cliente = una GV y un canal vigente).
WITH base AS (
  SELECT
    v.mes,
    v.cliente_id,
    c.gerencia,
    CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END AS canal,
    SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    ON v.cliente_id = c.cliente_id
  WHERE v.mes BETWEEN '202301' AND '202610'
    AND c.direccion = 'PE Dir Centro Orient'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY v.mes, v.cliente_id, c.gerencia,
    CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END
)
SELECT mes, gerencia, canal,
  COUNT(CASE WHEN hl > 0 THEN 1 END) AS pocs,
  SUM(hl) AS hl
FROM base
GROUP BY mes, gerencia, canal
ORDER BY 1, 2, 3
