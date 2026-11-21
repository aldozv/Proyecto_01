/* Venta Beer+Rtds (Cervezas + Licores + Ready To Drink) YTD Ene-Oct de 2023 a 2026 por cliente de Centro Oriente,
   agrupada por segmento del cliente para explicar la variacion YTD26 vs YTD25.
   Universo: clientes con direccion vigente Centro Oriente en dm_cliente (regla de atribucion vigente, CLAUDE.md).
   en_cartera = 'Cartera' si cumple los filtros del maestro (8 digitos, sin DAs Sellout ni Consumidor, nunca
   Marketplace/'SUPERVISOR PRUEBA'); el resto es 'Fuera de cartera' (se reporta aparte para cuadrar el total).
   cohorte por anio de fecha_alta: 'Nuevo 2026', 'Nuevo 2025', 'Antiguo' (alta antes de 2025).
   comportamiento: compro en ambos YTD (25 y 26), solo en 2026, solo en 2025, o en ninguno.
   canal = unidad_negocio_revenue_volumen_meta vigente (High End se suma a DSD ON).
   estado_actual y generico (supervisor 'Promotor generico') son los de la foto vigente. */
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
    CASE WHEN YEAR(c.fecha_alta) >= 2026 THEN 'Nuevo 2026' WHEN YEAR(c.fecha_alta) = 2025 THEN 'Nuevo 2025' ELSE 'Antiguo' END AS cohorte,
    CASE WHEN c.estado = '1' THEN 'Activo' ELSE 'Inactivo' END AS estado_actual,
    CASE WHEN c.unidad_negocio_revenue_volumen_meta = 'High End' THEN 'DSD ON'
         ELSE COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') END AS canal,
    CASE WHEN LOWER(COALESCE(c.supervisor, '')) LIKE '%promotor gen%' THEN 1 ELSE 0 END AS generico
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  LEFT JOIN excl e ON c.cliente_id = e.cliente_id
  WHERE c.direccion = 'PE Dir Centro Orient'
),
v AS (
  SELECT v.cliente_id,
    SUM(CASE WHEN v.mes LIKE '2023%' THEN v.hl ELSE 0 END) AS hl_23,
    SUM(CASE WHEN v.mes LIKE '2024%' THEN v.hl ELSE 0 END) AS hl_24,
    SUM(CASE WHEN v.mes LIKE '2025%' THEN v.hl ELSE 0 END) AS hl_25,
    SUM(CASE WHEN v.mes LIKE '2026%' THEN v.hl ELSE 0 END) AS hl_26
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  WHERE v.mes IN ('202301','202302','202303','202304','202305','202306','202307','202308','202309','202310',
                  '202401','202402','202403','202404','202405','202406','202407','202408','202409','202410',
                  '202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                  '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY v.cliente_id
)
SELECT c.gv, c.canal, c.en_cartera, c.cohorte, c.estado_actual, c.generico,
  CASE WHEN COALESCE(v.hl_25, 0) > 0 AND COALESCE(v.hl_26, 0) > 0 THEN 'Compro ambos anios'
       WHEN COALESCE(v.hl_26, 0) > 0 THEN 'Solo compro 2026'
       WHEN COALESCE(v.hl_25, 0) > 0 THEN 'Solo compro 2025'
       ELSE 'Sin compra' END AS comportamiento,
  COUNT(*) AS clientes,
  SUM(CASE WHEN COALESCE(v.hl_25, 0) > 0 THEN 1 ELSE 0 END) AS compradores_25,
  SUM(CASE WHEN COALESCE(v.hl_26, 0) > 0 THEN 1 ELSE 0 END) AS compradores_26,
  SUM(COALESCE(v.hl_23, 0)) AS hl_ytd23,
  SUM(COALESCE(v.hl_24, 0)) AS hl_ytd24,
  SUM(COALESCE(v.hl_25, 0)) AS hl_ytd25,
  SUM(COALESCE(v.hl_26, 0)) AS hl_ytd26
FROM cli c
LEFT JOIN v ON c.cliente_id = v.cliente_id
GROUP BY 1,2,3,4,5,6,7
ORDER BY 1,2,3,4,5,6,7
