-- Total HL mensual SIN restricción de CD (headline real de cada gerencia, para los KPI del
-- resumen ejecutivo — no se ve afectado por el filtro de Centro del dashboard).
-- Direccion Centro Oriente, 5 gerencias (incluye DA Jun Puc, distribuidor autorizado).
SELECT
  v.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '202401' AND '202609'
  AND v.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY v.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY v.gerencia, anio, mes_num
