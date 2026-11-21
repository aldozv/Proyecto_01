-- DSD OFF, CD Pucallpa, Beer+Rtds: variacion Ene-Oct por tamano del POC en el anio base y por BEES, para pares 2024-2025 y 2025-2026.
-- Control de regresion a la media: si los POCs grandes tambien caian en 2024-2025, la caida de 2026 no es solo un hecho nuevo.
WITH cy AS (
  SELECT v.cliente_id, c.bees, CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, SUM(v.hl) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
  WHERE v.mes BETWEEN '202401' AND '202610' AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10
    AND c.gerencia = 'PE Ger P4 Pucall Hco' AND c.centro = 'CD Pucallpa' AND v.indicadores_comerciales = 1
    AND c.unidad_negocio_revenue_volumen_meta = 'DSD OFF'
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY 1,2,3
), piv AS (
  SELECT cliente_id, bees,
    GREATEST(SUM(CASE WHEN anio=2024 THEN hl ELSE 0 END),0) y24,
    GREATEST(SUM(CASE WHEN anio=2025 THEN hl ELSE 0 END),0) y25,
    GREATEST(SUM(CASE WHEN anio=2026 THEN hl ELSE 0 END),0) y26
  FROM cy GROUP BY 1,2
), pares AS (
  SELECT '2024-2025' par, cliente_id, bees, y24 a, y25 b FROM piv
  UNION ALL SELECT '2025-2026', cliente_id, bees, y25, y26 FROM piv
)
SELECT par, bees,
  CASE WHEN a=0 THEN '0 nuevo' WHEN a<20 THEN '1 <20' WHEN a<50 THEN '2 20-50' WHEN a<100 THEN '3 50-100' WHEN a<300 THEN '4 100-300' ELSE '5 300+' END AS tamano,
  COUNT(1) AS pocs, SUM(a) AS hl_ini, SUM(b) AS hl_fin
FROM pares WHERE a>0 OR b>0
GROUP BY 1,2,3
ORDER BY 1,3,2
