/* Frecuencia de visita de la cartera de Centro Oriente por mes (ene'25 - oct'26) y su venta Beer+Rtds del mismo mes.
   Cartera y GV historica: mismas reglas que Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql (foto mensual
   de dm_hm_cliente, exclusion de Marketplace/'SUPERVISOR PRUEBA' a nivel cliente).
   frecuencia = dm_hm_cliente.frecuencia_visita (Bisemanal, Semanal, Quincenal, Mensual, OTROS, vacio = sin visita).
   generico = supervisor 'Promotor generico' en esa foto; canal = unidad_negocio_revenue_volumen_meta de esa foto. */
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
    MAX(CASE WHEN LOWER(COALESCE(h.supervisor, '')) LIKE '%promotor gen%' THEN 1 ELSE 0 END) AS generico,
    MAX(CASE WHEN h.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
             ELSE COALESCE(h.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END) AS canal
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente h
  LEFT ANTI JOIN excl e ON h.cliente_id = e.cliente_id
  WHERE h.mes BETWEEN '202501' AND '202610'
    AND h.estado = '1' AND LEN(h.cliente_id) = 8
    AND h.unidad_negocio NOT LIKE 'DAs Sellout' AND h.unidad_negocio NOT LIKE 'Consumidor'
  GROUP BY h.mes, h.cliente_id
),
v AS (
  SELECT v.mes, v.cliente_id, SUM(v.hl) AS hl
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  WHERE v.mes BETWEEN '202501' AND '202610'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY v.mes, v.cliente_id
)
SELECT c.mes, c.gv, c.canal, c.frecuencia, c.generico,
  COUNT(*) AS clientes,
  SUM(CASE WHEN v.hl > 0 THEN 1 ELSE 0 END) AS compradores,
  SUM(COALESCE(v.hl, 0)) AS hl
FROM c LEFT JOIN v ON v.mes = c.mes AND v.cliente_id = c.cliente_id
WHERE c.gv IS NOT NULL
GROUP BY 1,2,3,4,5
ORDER BY 1,2,3,4,5
