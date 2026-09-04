-- YTD (Ene-Ago) 2025 vs 2026, por gerencia x categoria (Beer=Cervezas+Licores, Rtds=Ready To Drink,
-- Nabs=Gaseosas+Agua+Maltas). Usado para poblar la referencia de Nabs por gerencia en el dashboard
-- "Ejecutivo Volumen - CO" (Nabs se muestra solo como referencia, no se suma a Beer+Rtds).
SELECT
  v.gerencia,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    ELSE 'Nabs'
  END AS categoria_grupo,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '202501' AND '202608'
  AND SUBSTR(v.mes,5,2) BETWEEN '01' AND '08'
  AND v.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY v.gerencia, categoria_grupo, CAST(SUBSTR(v.mes,1,4) AS INT)
ORDER BY v.gerencia, categoria_grupo, anio
