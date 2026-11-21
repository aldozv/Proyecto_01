/* Cambio de frecuencia de visita por cliente entre oct'25 y oct'26 y su venta Beer+Rtds YTD (Ene-Oct) 2025 vs 2026.
   Universo: clientes en la cartera de Centro Oriente en oct'25 y/o oct'26 (foto mensual de dm_hm_cliente, mismas
   reglas y exclusiones que Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql). GV = la de oct'26 si esta en
   cartera, si no la de oct'25 (igual canal). 'No en cartera' = el cliente no estaba en la cartera en ese mes. */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_cliente
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
c AS (
  SELECT h.mes, h.cliente_id,
    MAX(CASE
      WHEN h.gerencia = 'PE Ger P4 Tarapoto' THEN 'Tarapoto'
      WHEN h.gerencia = 'PE Ger P4 Iquitos' THEN 'Iquitos'
      WHEN h.gerencia IN ('PE Ger P4 Pucallpa', 'PE Ger P4 Huánuc Tma', 'PE Ger P4 Pucall Hco') THEN 'Pucall Hco'
      WHEN h.gerencia IN ('PE Ger P4 Chanchamay', 'PE Ger P3 Huancayo', 'PE Ger P4 Huancay Ch') THEN 'Huancay Ch'
      WHEN h.gerencia = 'PE Ger P4 DA Jun Puc' THEN 'DA Jun Puc' END) AS gv,
    MAX(COALESCE(NULLIF(TRIM(h.frecuencia_visita), ''), 'Sin visita')) AS frecuencia,
    MAX(CASE WHEN h.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
             ELSE COALESCE(h.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END) AS canal,
    MAX(CASE WHEN LOWER(COALESCE(h.supervisor, '')) LIKE '%promotor gen%' THEN 1 ELSE 0 END) AS generico
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente h
  LEFT ANTI JOIN excl e ON h.cliente_id = e.cliente_id
  WHERE h.mes IN ('202510', '202610')
    AND h.estado = '1' AND LEN(h.cliente_id) = 8
    AND h.unidad_negocio NOT LIKE 'DAs Sellout' AND h.unidad_negocio NOT LIKE 'Consumidor'
  GROUP BY h.mes, h.cliente_id
),
p AS (
  SELECT cliente_id,
    MAX(CASE WHEN mes = '202510' AND gv IS NOT NULL THEN frecuencia END) AS frec_25,
    MAX(CASE WHEN mes = '202610' AND gv IS NOT NULL THEN frecuencia END) AS frec_26,
    COALESCE(MAX(CASE WHEN mes = '202610' THEN gv END), MAX(CASE WHEN mes = '202510' THEN gv END)) AS gv,
    COALESCE(MAX(CASE WHEN mes = '202610' AND gv IS NOT NULL THEN canal END), MAX(CASE WHEN mes = '202510' THEN canal END)) AS canal,
    COALESCE(MAX(CASE WHEN mes = '202610' AND gv IS NOT NULL THEN generico END), 0) AS generico_oct26
  FROM c
  GROUP BY cliente_id
),
v AS (
  SELECT v.cliente_id,
    SUM(CASE WHEN v.mes LIKE '2025%' THEN v.hl ELSE 0 END) AS hl_25,
    SUM(CASE WHEN v.mes LIKE '2026%' THEN v.hl ELSE 0 END) AS hl_26
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  WHERE v.mes IN ('202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                  '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY v.cliente_id
)
SELECT p.gv, p.canal, p.generico_oct26,
  COALESCE(p.frec_25, 'No en cartera') AS frec_oct25,
  COALESCE(p.frec_26, 'No en cartera') AS frec_oct26,
  COUNT(*) AS clientes,
  SUM(CASE WHEN COALESCE(v.hl_25, 0) > 0 THEN 1 ELSE 0 END) AS compradores_25,
  SUM(CASE WHEN COALESCE(v.hl_26, 0) > 0 THEN 1 ELSE 0 END) AS compradores_26,
  SUM(COALESCE(v.hl_25, 0)) AS hl_ytd25,
  SUM(COALESCE(v.hl_26, 0)) AS hl_ytd26
FROM p LEFT JOIN v ON p.cliente_id = v.cliente_id
WHERE p.gv IS NOT NULL
GROUP BY 1,2,3,4,5
ORDER BY 1,2,3,4,5
