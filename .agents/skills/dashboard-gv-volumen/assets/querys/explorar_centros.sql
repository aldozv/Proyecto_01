-- Paso 1 (exploratorio, correr UNA vez por lote de gerencias nuevas): que CD aparecen para
-- cada gerencia y con que volumen -- sirve para decidir el CD_LIST del dashboard por gerencia
-- (los CD marginales/de otras gerencias vecinas normalmente se excluyen, salvo el patron
-- canal DAs -- ver reglas_negocio.md). Reemplazar {{GERENCIA_IN_LIST}} con la lista de codigos
-- transaccionales entre comillas simples separados por coma, ej:
--   'PE Ger P4 Tarapoto','PE Ger P4 Iquitos'
-- Usa el mes mas reciente disponible nomas (no todo el rango) para que sea rapido.
SELECT
  v.gerencia,
  c.centro,
  COUNT(*) AS filas,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes = '{{MES_HASTA}}'
  AND v.gerencia IN ({{GERENCIA_IN_LIST}})
  AND v.indicadores_comerciales = 1
GROUP BY v.gerencia, c.centro
ORDER BY v.gerencia, hl DESC
