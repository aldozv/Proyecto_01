-- Total HL mensual SIN restriccion de CD (headline real de cada gerencia -- alimenta los KPI
-- del resumen ejecutivo, que NO se ven afectados por los filtros de Centro/Categoria del
-- dashboard). Cubre todas las gerencias del run en una sola pasada.
-- Reemplazar {{GERENCIA_IN_LIST}} (codigos entre comillas separados por coma) y
-- {{MES_DESDE}}/{{MES_HASTA}} (yyyymm).
SELECT
  v.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'
  AND v.gerencia IN ({{GERENCIA_IN_LIST}})
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY v.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY v.gerencia, anio, mes_num
