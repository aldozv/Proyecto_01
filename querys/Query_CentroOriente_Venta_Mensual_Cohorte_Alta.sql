/* Venta Beer+Rtds mensual (ene'23 - oct'26) de los clientes de Centro Oriente, por GV vigente y anio de alta
   del cliente (cohorte), para ver cuanto volumen aporta cada generacion de clientes mes a mes.
   Mismo universo y definicion de cartera que Query_CentroOriente_Venta_Cartera_Cohorte_YTD.sql. */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_cliente
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
cli AS (
  SELECT c.cliente_id,
    REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv,
    CASE WHEN e.cliente_id IS NULL AND LEN(c.cliente_id) = 8
          AND c.unidad_negocio NOT LIKE 'DAs Sellout' AND c.unidad_negocio NOT LIKE 'Consumidor'
         THEN 'Cartera' ELSE 'Fuera de cartera' END AS en_cartera,
    CASE WHEN YEAR(c.fecha_alta) <= 2022 THEN 'Antes de 2023' ELSE CAST(YEAR(c.fecha_alta) AS STRING) END AS cohorte
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  LEFT JOIN excl e ON c.cliente_id = e.cliente_id
  WHERE c.direccion = 'PE Dir Centro Orient'
),
v AS (
  SELECT v.mes, v.cliente_id, SUM(v.hl) AS hl
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  WHERE v.mes BETWEEN '202301' AND '202610'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY v.mes, v.cliente_id
)
SELECT v.mes, c.gv, c.en_cartera, c.cohorte,
  SUM(v.hl) AS hl,
  SUM(CASE WHEN v.hl > 0 THEN 1 ELSE 0 END) AS compradores
FROM v JOIN cli c ON v.cliente_id = c.cliente_id
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4
