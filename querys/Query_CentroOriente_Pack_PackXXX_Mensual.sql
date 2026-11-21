-- Gerencia x Categoria x Pack x Pack XXX mensual (Centro Oriente, Ene-Set 2025 vs 2026). Alimenta los
-- building blocks "Por Pack XXX" y "Por Pack" del reporte ejecutivo de volumen.
-- pack = formato exacto (ej. "355 CAN", "620 RB"); pack_xxx = agrupacion gruesa (ej. "CAN XXX", "RB 6XX").
-- Fuente revenue_maestro_sku (carga manual): validar que "Sin mapear" no traiga volumen relevante.
-- Gerencia desde dm_cliente (regla vigente 2026-09-04), mismos filtros/CDs que Query_CentroOriente_Canal_CD_Categoria_Mensual.sql.
SELECT
  c.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(r.pack, 'Sin mapear') AS pack,
  COALESCE(r.pack_xxx, 'Sin mapear') AS pack_xxx,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE (v.mes BETWEEN '202501' AND '202509' OR v.mes BETWEEN '202601' AND '202609')
  AND c.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ('CD Pucallpa','CD Huánuco','CD Tingo María','CD Tarapoto','CD Yurimaguas','CD Moyobamba','CD Iquitos','CD Huancayo','CD Chanchamayo','CD Satipo','CD Huancavelica','CD San Benedicto I (Ate)','CD Motupe','CD Chiclayo')
GROUP BY
  c.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT),
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(r.pack, 'Sin mapear'), COALESCE(r.pack_xxx, 'Sin mapear')
ORDER BY c.gerencia, anio, mes_num, categoria_grupo, pack
