/* Clientes de la cartera vigente de Centro Oriente por GV, tipo de supervisor (promotor generico vs supervisor
   real) y fecha de alta, con cuantos compraron (HL > 0, indicadores_comerciales = 1) desde el 01.08.26.
   Mismo alcance y exclusiones que Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql (mes en curso). */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_cliente
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
c AS (
  SELECT c.cliente_id, REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv,
    CASE WHEN LOWER(c.supervisor) LIKE '%promotor gen%' THEN 'generico' ELSE 'supervisor' END AS tipo,
    CASE WHEN c.fecha_alta >= '2026-09-01' THEN 'alta set-nov26' ELSE 'alta previa' END AS alta
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  LEFT ANTI JOIN excl e ON c.cliente_id = e.cliente_id
  WHERE c.direccion = 'PE Dir Centro Orient' AND c.estado = '1' AND LEN(c.cliente_id) = 8
    AND c.unidad_negocio NOT LIKE 'DAs Sellout' AND c.unidad_negocio NOT LIKE 'Consumidor'
),
v AS (
  SELECT cliente_id, SUM(hl) AS hl
  FROM slv_maz_dataexperience_peru_dm.dm_venta
  WHERE fecha_venta >= '2026-08-01' AND indicadores_comerciales = 1
  GROUP BY cliente_id
)
SELECT c.gv, c.tipo, c.alta, COUNT(*) AS clientes, SUM(CASE WHEN v.hl > 0 THEN 1 ELSE 0 END) AS con_compra_ago_nov26
FROM c LEFT JOIN v ON c.cliente_id = v.cliente_id
GROUP BY 1,2,3
ORDER BY 1,2,3
