/* Flujos de la cartera de clientes activos de Centro Oriente vs mes anterior (LM), por GV y Total Direccion.
   Mismo alcance, mapeo historico de GV y exclusiones que Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql.
   Entradas a una GV (en su cartera hoy, no en LM):
     alta_nueva = el codigo no existia en el maestro LM; reactivacion = existia inactivo;
     otra_gv_co = estaba en la cartera de otra GV de Centro Oriente; fuera = estaba activo fuera del alcance
     (otra direccion, DAs Sellout, Consumidor, Marketplace).
   Salidas (en cartera LM, no hoy): inactivado / otra_gv_co / fuera / fuera_maestro (el codigo ya no aparece).
   En 'Total Direccion' los traslados entre GV de la region se netean (otra_gv_co = 0).
   202602 trae duplicados en dm_hm_cliente: se colapsa a 1 fila por cliente-mes con MAX. */
WITH raw AS (
  SELECT mes, cliente_id, gerencia, estado, unidad_negocio, subcanal, supervisor
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes BETWEEN '202212' AND '202610' AND LEN(cliente_id) = 8
  UNION ALL
  SELECT mes, cliente_id, gerencia, estado, unidad_negocio, subcanal, supervisor
  FROM slv_maz_dataexperience_peru_dm.dm_cliente
  WHERE LEN(cliente_id) = 8
),
excl AS (
  -- clientes de prueba/Marketplace: fuera de la cartera en TODO el historico (cuentan como "fuera del alcance")
  SELECT DISTINCT cliente_id FROM raw
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
flag AS (
  SELECT r.mes, r.cliente_id,
    MAX(CASE WHEN r.estado = '1' AND e.cliente_id IS NULL
              AND r.unidad_negocio NOT LIKE 'DAs Sellout' AND r.unidad_negocio NOT LIKE 'Consumidor'
             THEN CASE
               WHEN gerencia = 'PE Ger P4 Tarapoto' THEN 'Tarapoto'
               WHEN gerencia = 'PE Ger P4 Iquitos' THEN 'Iquitos'
               WHEN gerencia IN ('PE Ger P4 Pucallpa', 'PE Ger P4 Huánuc Tma', 'PE Ger P4 Pucall Hco') THEN 'Pucall Hco'
               WHEN gerencia IN ('PE Ger P4 Chanchamay', 'PE Ger P3 Huancayo', 'PE Ger P4 Huancay Ch') THEN 'Huancay Ch'
               WHEN gerencia = 'PE Ger P4 DA Jun Puc' THEN 'DA Jun Puc'
             END END) AS gv,
    MAX(CASE WHEN r.estado = '1' THEN 1 ELSE 0 END) AS activo
  FROM raw r LEFT JOIN excl e ON r.cliente_id = e.cliente_id
  GROUP BY r.mes, r.cliente_id
),
ids AS (SELECT DISTINCT cliente_id FROM flag WHERE gv IS NOT NULL),
meses AS (
  SELECT DISTINCT mes, DATE_FORMAT(ADD_MONTHS(TO_DATE(mes, 'yyyyMM'), -1), 'yyyyMM') AS mes_lm
  FROM flag WHERE mes >= '202301'
),
grid AS (
  SELECT m.mes, a.gv AS hoy_gv, a.activo AS hoy_activo, b.gv AS lm_gv, b.activo AS lm_activo
  FROM meses m
  CROSS JOIN ids i
  LEFT JOIN flag a ON a.mes = m.mes AND a.cliente_id = i.cliente_id
  LEFT JOIN flag b ON b.mes = m.mes_lm AND b.cliente_id = i.cliente_id
),
ev AS (
  -- stock hoy y LM
  SELECT mes, hoy_gv AS gv, 'cartera' AS tipo FROM grid WHERE hoy_gv IS NOT NULL
  UNION ALL SELECT mes, 'Total Direccion', 'cartera' FROM grid WHERE hoy_gv IS NOT NULL
  UNION ALL SELECT mes, lm_gv, 'cartera_lm' FROM grid WHERE lm_gv IS NOT NULL
  UNION ALL SELECT mes, 'Total Direccion', 'cartera_lm' FROM grid WHERE lm_gv IS NOT NULL
  -- entradas por GV
  UNION ALL
  SELECT mes, hoy_gv,
    CASE WHEN lm_activo IS NULL THEN 'ent_alta_nueva' WHEN lm_activo = 0 THEN 'ent_reactivacion'
         WHEN lm_gv IS NOT NULL THEN 'ent_otra_gv_co' ELSE 'ent_fuera' END
  FROM grid WHERE hoy_gv IS NOT NULL AND (lm_gv IS NULL OR lm_gv <> hoy_gv)
  -- salidas por GV
  UNION ALL
  SELECT mes, lm_gv,
    CASE WHEN hoy_activo IS NULL THEN 'sal_fuera_maestro' WHEN hoy_activo = 0 THEN 'sal_inactivado'
         WHEN hoy_gv IS NOT NULL THEN 'sal_otra_gv_co' ELSE 'sal_fuera' END
  FROM grid WHERE lm_gv IS NOT NULL AND (hoy_gv IS NULL OR hoy_gv <> lm_gv)
  -- entradas y salidas de la Direccion
  UNION ALL
  SELECT mes, 'Total Direccion',
    CASE WHEN lm_activo IS NULL THEN 'ent_alta_nueva' WHEN lm_activo = 0 THEN 'ent_reactivacion' ELSE 'ent_fuera' END
  FROM grid WHERE hoy_gv IS NOT NULL AND lm_gv IS NULL
  UNION ALL
  SELECT mes, 'Total Direccion',
    CASE WHEN hoy_activo IS NULL THEN 'sal_fuera_maestro' WHEN hoy_activo = 0 THEN 'sal_inactivado' ELSE 'sal_fuera' END
  FROM grid WHERE lm_gv IS NOT NULL AND hoy_gv IS NULL
)
SELECT mes, gv,
  SUM(CASE WHEN tipo = 'cartera' THEN 1 ELSE 0 END) AS cartera,
  SUM(CASE WHEN tipo = 'cartera_lm' THEN 1 ELSE 0 END) AS cartera_lm,
  SUM(CASE WHEN tipo = 'ent_alta_nueva' THEN 1 ELSE 0 END) AS ent_alta_nueva,
  SUM(CASE WHEN tipo = 'ent_reactivacion' THEN 1 ELSE 0 END) AS ent_reactivacion,
  SUM(CASE WHEN tipo = 'ent_otra_gv_co' THEN 1 ELSE 0 END) AS ent_otra_gv_co,
  SUM(CASE WHEN tipo = 'ent_fuera' THEN 1 ELSE 0 END) AS ent_fuera,
  SUM(CASE WHEN tipo = 'sal_inactivado' THEN 1 ELSE 0 END) AS sal_inactivado,
  SUM(CASE WHEN tipo = 'sal_otra_gv_co' THEN 1 ELSE 0 END) AS sal_otra_gv_co,
  SUM(CASE WHEN tipo = 'sal_fuera' THEN 1 ELSE 0 END) AS sal_fuera,
  SUM(CASE WHEN tipo = 'sal_fuera_maestro' THEN 1 ELSE 0 END) AS sal_fuera_maestro
FROM ev
GROUP BY mes, gv
ORDER BY mes, gv
