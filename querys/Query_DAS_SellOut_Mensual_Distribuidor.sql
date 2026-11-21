-- DAS Sell Out Centro Oriente, mensual Ene'23-Oct'26, Beer+Rtds, por gerencia (dm_das_cliente) y distribuidor (razon_social).
SELECT v.mes, c.gerencia, v.razon_social, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND v.indicadores_comerciales = 1
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY ALL
ORDER BY 1, 2, 3
