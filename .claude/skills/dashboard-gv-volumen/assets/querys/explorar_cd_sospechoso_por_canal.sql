-- Paso 1b (exploratorio, correr solo si el Paso 1 muestra un CD con volumen NO trivial en una
-- gerencia donde geograficamente no deberia estar -- ver el caso Tarapoto/CD Pucallpa en
-- reglas_negocio.md): desglosa ese CD sospechoso por canal para confirmar si es el patron DAs
-- (Distribuidores Autorizados que se abastecen del CD mas grande sin importar la gerencia de
-- facturacion) u otra cosa. Reemplazar {{GERENCIA_IN_LIST}} y {{CD_SOSPECHOSO}}.
SELECT
  v.gerencia,
  c.centro,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes = '{{MES_HASTA}}'
  AND v.gerencia IN ({{GERENCIA_IN_LIST}})
  AND c.centro = '{{CD_SOSPECHOSO}}'
  AND v.indicadores_comerciales = 1
GROUP BY v.gerencia, c.centro, COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar')
ORDER BY v.gerencia, hl DESC
