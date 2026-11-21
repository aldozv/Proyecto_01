-- CD Pucallpa (GV Pucallpa): detalle por cliente, Ene-Oct 2025 vs Ene-Oct 2026, para perfilar POCs perdidos de DSD OFF
-- y probar migracion a Mayoristas/Eventos. Documento y direccion viajan como hash: sirven para detectar
-- recodificacion de un mismo negocio sin traer el dato personal.
WITH base AS (
  SELECT v.cliente_id, v.mes, v.hl,
    CASE WHEN v.estratificacion IN ('Cervezas','Licores','Ready To Drink') THEN 1 ELSE 0 END AS es_br,
    CASE WHEN m.marca = 'San Juan' AND r.pack = '620 RB' THEN 1 ELSE 0 END AS es_sj620
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
  LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
  LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id = r.sku
  WHERE v.mes BETWEEN '202501' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND c.centro = 'CD Pucallpa'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
    AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
), a AS (
  SELECT cliente_id,
    SUM(CASE WHEN es_br=1 AND mes BETWEEN '202501' AND '202510' THEN hl ELSE 0 END) hl25,
    SUM(CASE WHEN es_br=1 AND mes BETWEEN '202511' AND '202512' THEN hl ELSE 0 END) hl_nd25,
    SUM(CASE WHEN es_br=1 AND mes BETWEEN '202601' AND '202610' THEN hl ELSE 0 END) hl26,
    SUM(CASE WHEN es_br=1 AND es_sj620=1 AND mes BETWEEN '202501' AND '202510' THEN hl ELSE 0 END) sj25,
    SUM(CASE WHEN es_br=1 AND es_sj620=1 AND mes BETWEEN '202601' AND '202610' THEN hl ELSE 0 END) sj26,
    SUM(CASE WHEN es_br=0 AND mes BETWEEN '202601' AND '202610' THEN hl ELSE 0 END) nabs26,
    MAX(CASE WHEN es_br=1 AND hl>0 THEN mes END) ult_mes,
    COUNT(DISTINCT CASE WHEN es_br=1 AND hl>0 AND mes BETWEEN '202501' AND '202510' THEN mes END) meses25,
    COUNT(DISTINCT CASE WHEN es_br=1 AND hl>0 AND mes BETWEEN '202601' AND '202610' THEN mes END) meses26
  FROM base GROUP BY cliente_id
)
SELECT a.cliente_id, a.hl25, a.hl_nd25, a.hl26, a.sj25, a.sj26, a.nabs26, a.ult_mes, a.meses25, a.meses26,
  c.nombre, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') canal, c.supervisor, c.vendedor_id, c.vendedor_nombre, c.vendedor,
  c.zona_venta, c.distrito, c.provincia, c.localidad, c.subcanal, c.subcanal_local, c.bees_segmento, c.obppc_cluster, c.estado, c.fecha_alta, c.fecha_baja, c.bees, c.frecuencia_visita,
  SHA2(c.numero_documento,256) doc_hash, SHA2(UPPER(TRIM(c.direccion_geo)),256) dir_hash, ROUND(c.x,4) x4, ROUND(c.y,4) y4
FROM a INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON a.cliente_id = c.cliente_id
LIMIT 12000
