-- CD x Categoria x Canal x Pack (pack_xxx, via revenue_maestro_sku) mensual, todas las
-- gerencias del run. Alimenta "Por Pack" y el filtro global de Canal. pack_xxx es una
-- agrupacion mas gruesa que pack (Formato): agrupa
-- envase + rango de mililitraje redondeado (ej. "CAN XXX", "RB 6XX", "NRB 3XX", "KEG XXX") en
-- vez del formato exacto ("355 CAN", "620 RB"). revenue_maestro_sku es de carga manual (ver
-- BITACORA_TABLAS.md) -- validar cobertura de join (columna "Sin mapear" no deberia traer
-- volumen relevante; si lo trae, avisar al usuario antes de confiar en la seccion Pack).
-- Mismos placeholders que base_cd_categoria_mensual.sql.
-- CORREGIDO 2026-09-06: gerencia sale de dm_cliente (vigente), no de dm_venta -- ver CLAUDE.md
-- (caso Ucayali Beer, reasignado Huancay Ch -> DA Jun Puc en abril 2026).
SELECT
  c.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  COALESCE(r.pack_xxx, 'Sin mapear') AS pack_xxx,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'
  AND c.gerencia IN ({{GERENCIA_IN_LIST}})
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ({{CD_IN_LIST}})
GROUP BY
  c.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar'),
  COALESCE(r.pack_xxx, 'Sin mapear')
ORDER BY c.gerencia, anio, mes_num, centro, categoria_grupo, canal_meta, pack_xxx
