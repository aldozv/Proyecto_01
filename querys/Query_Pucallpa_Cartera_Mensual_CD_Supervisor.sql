/* Cartera de clientes activos de la GV Pucallpa por mes, CD y supervisor (Ene'23 - Nov'26).
   Fuente: dm_hm_cliente (fotos de cierre 202212-202610) + dm_cliente (foto vigente = mes en curso).
   GV Pucallpa = 'PE Ger P4 Pucall Hco' desde feb'26; hasta ene'26 = 'PE Ger P4 Pucallpa' + 'PE Ger P4 Huánuc Tma'
   (se fusionaron en la reestructuracion de inicios de 2026; dm_hm_cliente no se reescribe).
   Cartera = mismos filtros del query maestro del usuario: estado = '1', sin DAs Sellout ni Consumidor, codigo de 8 digitos.
   Gerencia, CD y supervisor son los de cada foto mensual (como estaba el cliente ese mes).
   202602 trae clientes duplicados en dm_hm_cliente: se cuenta COUNT(DISTINCT cliente_id). */
WITH base AS (
  SELECT mes, cliente_id, centro_id, centro, supervisor_id, supervisor
  FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes BETWEEN '202212' AND '202610'
    AND gerencia IN ('PE Ger P4 Pucallpa', 'PE Ger P4 Huánuc Tma', 'PE Ger P4 Pucall Hco')
    AND estado = '1'
    AND unidad_negocio NOT LIKE 'DAs Sellout' AND unidad_negocio NOT LIKE 'Consumidor'
    AND LEN(cliente_id) = 8
  UNION ALL
  SELECT date_format(from_utc_timestamp(current_timestamp(), 'America/Lima'), 'yyyyMM') as mes, dm_cliente.customer_short_code as cliente_id, dm_cliente.distribution_center_code as centro_id, dm_cliente.distribution_center_name as centro, dm_cliente.sales_subregion_code as supervisor_id, dm_cliente.sales_subregion_name as supervisor
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer dm_cliente
  WHERE dm_cliente.sales_region_name = 'PE Ger P4 Pucall Hco'
    AND dm_cliente.customer_status = '1'
    AND dm_cliente.business_unit NOT LIKE 'DAs Sellout' AND dm_cliente.business_unit NOT LIKE 'Consumidor'
    AND LEN(dm_cliente.customer_short_code) = 8
)
SELECT mes, centro_id, centro, supervisor_id, supervisor,
  COUNT(DISTINCT cliente_id) AS clientes_activos
FROM base
GROUP BY mes, centro_id, centro, supervisor_id, supervisor
ORDER BY mes, centro_id, supervisor_id
