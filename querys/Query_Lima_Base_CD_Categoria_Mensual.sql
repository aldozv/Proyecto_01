-- Base Direccion Lima: gerencia x mes x CD x categoria x canal (HL), Ene-Oct 2025 y Ene-Oct 2026.
-- Alimenta el artifact "Ejecutivo Volumen - Lima" (misma estructura que el de Centro Oriente).
-- Gerencia, centro y canal salen de dm_cliente (vigente). Sin filtro de CD: Lima no tiene lista
-- curada de CDs; se toman todos los centros donde estan registrados sus clientes.
SELECT
  c.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  COALESCE(c.centro, 'Sin centro') AS centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE (v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610')
  AND c.direccion = 'PE Dir Lima'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY 1,2,3,4,5,6
ORDER BY 1,2,3,4,5,6
LIMIT 20000
