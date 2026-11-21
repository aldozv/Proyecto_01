-- POCs compradores distintos en el YTD Ene-Oct de cada anio (HL neto > 0 en el periodo), Beer+Rtds, por gerencia x canal vigente.
-- Direccion Centro Oriente, 2023-2026. Mide cobertura acumulada del periodo (no promedio mensual).
WITH base AS (
  SELECT
    SUBSTR(v.mes, 1, 4) AS anio,
    v.cliente_id,
    c.gerencia,
    CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END AS canal,
    SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    ON v.cliente_id = c.cliente_id
  WHERE v.mes IN ('202301','202302','202303','202304','202305','202306','202307','202308','202309','202310',
                  '202401','202402','202403','202404','202405','202406','202407','202408','202409','202410',
                  '202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                  '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND c.direccion = 'PE Dir Centro Orient'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY SUBSTR(v.mes, 1, 4), v.cliente_id, c.gerencia,
    CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END
)
SELECT anio, gerencia, canal,
  COUNT(CASE WHEN hl > 0 THEN 1 END) AS pocs,
  SUM(hl) AS hl
FROM base
GROUP BY anio, gerencia, canal
ORDER BY 1, 2, 3
