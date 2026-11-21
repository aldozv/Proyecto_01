-- GV Pucallpa: Beer+Rtds YTD Ene-Oct 2025 vs 2026 por CD x supervisor x vendedor x canal, con POCs activos.
WITH cy AS (
  SELECT CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, v.cliente_id, c.centro, COALESCE(c.supervisor,'Sin supervisor') AS supervisor,
    COALESCE(c.vendedor,'Sin vendedor') AS vendedor, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal, SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
  WHERE v.mes BETWEEN '202501' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1 AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY 1,2,3,4,5,6
)
SELECT centro, supervisor, vendedor, canal,
  SUM(CASE WHEN anio=2025 THEN hl ELSE 0 END) AS hl_25, SUM(CASE WHEN anio=2026 THEN hl ELSE 0 END) AS hl_26,
  COUNT(DISTINCT CASE WHEN anio=2025 AND hl>0 THEN cliente_id END) AS pocs_25, COUNT(DISTINCT CASE WHEN anio=2026 AND hl>0 THEN cliente_id END) AS pocs_26
FROM cy GROUP BY 1,2,3,4
