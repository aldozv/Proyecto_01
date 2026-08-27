-- Ventas (HL) y rentabilidad (NR) mensual, gerencia Pucallpa, 2023 (base LY para comparar 2024)
SELECT
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl,
  SUM(v.nr) AS nr
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '202301' AND '202312'
  AND v.gerencia = 'PE Ger P4 Pucall Hco'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY anio, mes_num
