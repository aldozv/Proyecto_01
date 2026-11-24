/* Flujos de la cartera de clientes activos de la GV Pucallpa vs mes anterior (LM), Ene'23 - Nov'26.
   Mismo alcance y definicion de cartera que Query_Pucallpa_Cartera_Mensual_CD_Supervisor.sql.
   Para cada cliente que alguna vez estuvo en la cartera compara su foto del mes vs la del mes anterior:
   Entradas (en cartera hoy, no en LM):
     - Alta nueva:       el codigo no existia en el maestro LM
     - Reactivacion:     existia en LM pero inactivo (estado <> '1')
     - Ingreso de otra GV/canal: existia activo en LM pero en otra GV o en DAs Sellout/Consumidor
   Salidas (en cartera LM, no hoy):
     - Inactivado:       sigue en el maestro con estado <> '1'
     - Salida a otra GV/canal: sigue activo pero en otra GV o en DAs Sellout/Consumidor
     - Fuera del maestro: el codigo ya no aparece (depuracion)
   202602 trae duplicados en dm_hm_cliente: se colapsa a 1 fila por cliente-mes con MAX. */
WITH raw AS (
  SELECT mes, cliente_id, gerencia, estado, unidad_negocio
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes BETWEEN '202212' AND '202610'
    AND LEN(cliente_id) = 8
  UNION ALL
  SELECT date_format(from_utc_timestamp(current_timestamp(), 'America/Lima'), 'yyyyMM') as mes, dm_cliente.customer_short_code as cliente_id, dm_cliente.sales_region_name as gerencia, dm_cliente.customer_status as estado, dm_cliente.business_unit as unidad_negocio
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer dm_cliente
  WHERE LEN(dm_cliente.customer_short_code) = 8
),
flag AS (
  SELECT mes, cliente_id,
    MAX(CASE WHEN gerencia IN ('PE Ger P4 Pucallpa', 'PE Ger P4 Huánuc Tma', 'PE Ger P4 Pucall Hco')
              AND estado = '1'
              AND unidad_negocio NOT LIKE 'DAs Sellout' AND unidad_negocio NOT LIKE 'Consumidor'
             THEN 1 ELSE 0 END) AS en_cartera,
    MAX(CASE WHEN estado = '1' THEN 1 ELSE 0 END) AS activo
  FROM raw
  GROUP BY mes, cliente_id
),
ids AS (
  SELECT DISTINCT cliente_id FROM flag WHERE en_cartera = 1
),
meses AS (
  SELECT DISTINCT mes,
    DATE_FORMAT(ADD_MONTHS(TO_DATE(mes, 'yyyyMM'), -1), 'yyyyMM') AS mes_lm
  FROM flag
  WHERE mes >= '202301'
),
grid AS (
  SELECT m.mes, i.cliente_id,
    a.en_cartera AS hoy_cartera, a.activo AS hoy_activo,
    b.en_cartera AS lm_cartera, b.activo AS lm_activo
  FROM meses m
  CROSS JOIN ids i
  LEFT JOIN flag a ON a.mes = m.mes AND a.cliente_id = i.cliente_id
  LEFT JOIN flag b ON b.mes = m.mes_lm AND b.cliente_id = i.cliente_id
)
SELECT mes,
  SUM(CASE WHEN hoy_cartera = 1 THEN 1 ELSE 0 END) AS cartera,
  SUM(CASE WHEN lm_cartera = 1 THEN 1 ELSE 0 END) AS cartera_lm,
  SUM(CASE WHEN hoy_cartera = 1 AND COALESCE(lm_cartera, 0) = 0 AND lm_activo IS NULL THEN 1 ELSE 0 END) AS ent_alta_nueva,
  SUM(CASE WHEN hoy_cartera = 1 AND COALESCE(lm_cartera, 0) = 0 AND lm_activo = 0 THEN 1 ELSE 0 END) AS ent_reactivacion,
  SUM(CASE WHEN hoy_cartera = 1 AND COALESCE(lm_cartera, 0) = 0 AND lm_activo = 1 THEN 1 ELSE 0 END) AS ent_otra_gv,
  SUM(CASE WHEN lm_cartera = 1 AND COALESCE(hoy_cartera, 0) = 0 AND hoy_activo = 0 THEN 1 ELSE 0 END) AS sal_inactivado,
  SUM(CASE WHEN lm_cartera = 1 AND COALESCE(hoy_cartera, 0) = 0 AND hoy_activo = 1 THEN 1 ELSE 0 END) AS sal_otra_gv,
  SUM(CASE WHEN lm_cartera = 1 AND COALESCE(hoy_cartera, 0) = 0 AND hoy_activo IS NULL THEN 1 ELSE 0 END) AS sal_fuera_maestro
FROM grid
GROUP BY mes
ORDER BY mes
