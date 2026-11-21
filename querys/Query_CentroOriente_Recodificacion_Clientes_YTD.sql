/* Recodificacion de clientes: antiguos que dejaron de comprar en el YTD26 (compraron Ene-Oct 2025 y no Ene-Oct 2026)
   vs clientes nuevos (alta 2025 o 2026) que compran en el YTD26, cruzados por numero_documento (DNI/RUC).
   Si comparten documento, es el mismo negocio con codigo nuevo: el volumen "perdido" se traslado, no se perdio.
   Mismo universo y exclusiones que Query_CentroOriente_Venta_Cartera_Cohorte_YTD.sql. */
WITH excl AS (
  SELECT DISTINCT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_hm_cliente
  WHERE mes >= '202212' AND (UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%')
  UNION
  SELECT cliente_id FROM slv_maz_dataexperience_peru_dm.dm_cliente
  WHERE UPPER(COALESCE(supervisor, '')) LIKE '%PRUEBA%' OR COALESCE(subcanal, '') LIKE 'MTKP%'
),
cli AS (
  SELECT c.cliente_id, REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv,
    NULLIF(REGEXP_REPLACE(TRIM(c.numero_documento), '^0+', ''), '') AS doc,
    CASE WHEN YEAR(c.fecha_alta) >= 2025 THEN 'Nuevo' ELSE 'Antiguo' END AS cohorte
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  LEFT ANTI JOIN excl e ON c.cliente_id = e.cliente_id
  WHERE c.direccion = 'PE Dir Centro Orient' AND LEN(c.cliente_id) = 8
    AND c.unidad_negocio NOT LIKE 'DAs Sellout' AND c.unidad_negocio NOT LIKE 'Consumidor'
),
v AS (
  SELECT dv.cliente_id,
    SUM(CASE WHEN dv.mes LIKE '2025%' THEN dv.hl ELSE 0 END) AS hl_25,
    SUM(CASE WHEN dv.mes LIKE '2026%' THEN dv.hl ELSE 0 END) AS hl_26
  FROM slv_maz_dataexperience_peru_dm.dm_venta dv
  WHERE dv.mes IN ('202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND dv.indicadores_comerciales = 1
    AND dv.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY dv.cliente_id
),
x AS (
  SELECT c.*, COALESCE(v.hl_25, 0) AS hl_25, COALESCE(v.hl_26, 0) AS hl_26
  FROM cli c LEFT JOIN v ON c.cliente_id = v.cliente_id
),
perd AS (SELECT * FROM x WHERE cohorte = 'Antiguo' AND hl_25 > 0 AND hl_26 <= 0),
nuevos_doc AS (
  SELECT doc, SUM(hl_25) AS hl_25_n, SUM(hl_26) AS hl_26_n, COUNT(*) AS n_nuevos
  FROM x WHERE cohorte = 'Nuevo' AND hl_26 > 0 AND doc IS NOT NULL
  GROUP BY doc
)
SELECT p.gv,
  CASE WHEN p.doc IS NULL THEN 'Sin documento'
       WHEN n.doc IS NOT NULL THEN 'Recodificado (doc con codigo nuevo que compra)'
       ELSE 'Perdido real' END AS tipo,
  COUNT(*) AS clientes,
  SUM(p.hl_25) AS hl_ytd25_codigo_antiguo,
  SUM(COALESCE(n.hl_26_n, 0)) AS hl_ytd26_codigo_nuevo,
  SUM(COALESCE(n.hl_25_n, 0)) AS hl_ytd25_codigo_nuevo
FROM perd p LEFT JOIN nuevos_doc n ON p.doc = n.doc
GROUP BY 1,2
ORDER BY 1,2
