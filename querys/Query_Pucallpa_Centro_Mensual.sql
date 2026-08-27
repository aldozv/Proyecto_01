-- Ventas (HL) y rentabilidad (NR) mensual por CD/Centro, gerencia Pucallpa, 2024-2026
-- Centro viene de dm_cliente (snapshot ACTUAL, unica foto disponible - no historico por mes)
SELECT
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  COALESCE(c.centro, 'Sin clasificar') AS centro,
  SUM(v.hl) AS hl,
  SUM(v.nr) AS nr
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202401' AND '202608'
  AND v.gerencia = 'PE Ger P4 Pucall Hco'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT),
  COALESCE(c.centro, 'Sin clasificar')
ORDER BY anio, mes_num, centro
