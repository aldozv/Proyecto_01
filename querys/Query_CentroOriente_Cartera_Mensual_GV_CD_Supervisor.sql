/* Cartera de clientes activos de la Regional Centro Oriente por mes, GV, CD y supervisor (dic'22 - mes en curso).
   Fuente: dm_hm_cliente (fotos de cierre 202212-202610) + dm_cliente (foto vigente = mes en curso).
   Historia reconstruida a las 5 GV actuales (confirmado por el usuario 2026-11-11):
     Tarapoto   <- 'PE Ger P4 Tarapoto'
     Iquitos    <- 'PE Ger P4 Iquitos'
     Pucall Hco <- 'PE Ger P4 Pucallpa' + 'PE Ger P4 Huánuc Tma' (ex Dir Oriente) / 'PE Ger P4 Pucall Hco'
     Huancay Ch <- 'PE Ger P4 Chanchamay' (ex Dir Oriente) + 'PE Ger P3 Huancayo' (ex Dir Centro Sur) / 'PE Ger P4 Huancay Ch'
     DA Jun Puc <- 'PE Ger P4 DA Jun Puc' (existe desde feb'26)
   Cartera = estado '1', sin DAs Sellout ni Consumidor, codigo de 8 digitos.
   Excluye Marketplace (subcanal 'MTKP%', ej. ~1,350 clientes MTKP Gloria que pasaron de Lima Centro a Huancay Ch
   en feb'26) y supervisor 'SUPERVISOR PRUEBA' (decision del usuario 2026-11-11).
   GV, CD y supervisor son los de cada foto mensual. 202602 trae duplicados: se cuenta COUNT(DISTINCT cliente_id). */
WITH raw AS (
  SELECT mes, cliente_id, gerencia, centro_id, centro, supervisor_id, supervisor, estado, unidad_negocio, subcanal
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes BETWEEN '202212' AND '202610' AND LEN(cliente_id) = 8
  UNION ALL
  SELECT date_format(from_utc_timestamp(current_timestamp(), 'America/Lima'), 'yyyyMM') as mes, dm_cliente.customer_short_code as cliente_id, dm_cliente.sales_region_name as gerencia, dm_cliente.distribution_center_code as centro_id, dm_cliente.distribution_center_name as centro, dm_cliente.sales_subregion_code as supervisor_id, dm_cliente.sales_subregion_name as supervisor, dm_cliente.customer_status as estado, dm_cliente.business_unit as unidad_negocio, dm_cliente.subchannel_name as subcanal
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer dm_cliente
  WHERE LEN(dm_cliente.customer_short_code) = 8
),
excl AS (
  -- clientes de prueba/Marketplace: se excluyen en TODO el historico si alguna vez tuvieron esa marca
  -- (en nov'26 parte de 'SUPERVISOR PRUEBA' se renombro a 'Promotor generico PEDLF6')
  SELECT DISTINCT cliente_id FROM raw
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
base AS (
  SELECT mes, cliente_id, centro_id, centro, supervisor_id, supervisor,
    CASE
      WHEN gerencia = 'PE Ger P4 Tarapoto' THEN 'Tarapoto'
      WHEN gerencia = 'PE Ger P4 Iquitos' THEN 'Iquitos'
      WHEN gerencia IN ('PE Ger P4 Pucallpa', 'PE Ger P4 Huánuc Tma', 'PE Ger P4 Pucall Hco') THEN 'Pucall Hco'
      WHEN gerencia IN ('PE Ger P4 Chanchamay', 'PE Ger P3 Huancayo', 'PE Ger P4 Huancay Ch') THEN 'Huancay Ch'
      WHEN gerencia = 'PE Ger P4 DA Jun Puc' THEN 'DA Jun Puc'
    END AS gv
  FROM raw r LEFT ANTI JOIN excl e ON r.cliente_id = e.cliente_id
  WHERE estado = '1'
    AND unidad_negocio NOT LIKE 'DAs Sellout' AND unidad_negocio NOT LIKE 'Consumidor'
)
SELECT mes, gv, centro_id, centro, supervisor_id, supervisor,
  COUNT(DISTINCT cliente_id) AS clientes_activos
FROM base
WHERE gv IS NOT NULL
GROUP BY mes, gv, centro_id, centro, supervisor_id, supervisor
ORDER BY mes, gv, centro_id, supervisor_id
