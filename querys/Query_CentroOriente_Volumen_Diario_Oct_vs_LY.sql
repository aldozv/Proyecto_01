-- Volumen diario Beer+Rtds Centro Oriente, Oct 2025 completo vs Oct 2026 MTD, por gerencia (para ajuste de dias habiles).
SELECT c.gerencia, v.fecha_venta, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes IN ('202510','202610') AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2
