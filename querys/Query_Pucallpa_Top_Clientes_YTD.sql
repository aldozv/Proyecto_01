-- GV Pucallpa: clientes con mayor movimiento Beer+Rtds YTD Ene-Oct 2026 vs 2025 (y serie desde 2021).
SELECT v.cliente_id, MAX(c.nombre) AS nombre, c.centro, COALESCE(c.supervisor,'Sin supervisor') AS supervisor, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal, MAX(c.estado) AS estado,
  SUM(CASE WHEN v.mes LIKE '2021%' THEN v.hl ELSE 0 END) y21, SUM(CASE WHEN v.mes LIKE '2022%' THEN v.hl ELSE 0 END) y22,
  SUM(CASE WHEN v.mes LIKE '2023%' THEN v.hl ELSE 0 END) y23, SUM(CASE WHEN v.mes LIKE '2024%' THEN v.hl ELSE 0 END) y24,
  SUM(CASE WHEN v.mes LIKE '2025%' THEN v.hl ELSE 0 END) y25, SUM(CASE WHEN v.mes LIKE '2026%' THEN v.hl ELSE 0 END) y26
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202101' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1 AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.cliente_id, c.centro, COALESCE(c.supervisor,'Sin supervisor'), COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar')
ORDER BY ABS(SUM(CASE WHEN v.mes LIKE '2026%' THEN v.hl ELSE 0 END) - SUM(CASE WHEN v.mes LIKE '2025%' THEN v.hl ELSE 0 END)) DESC
LIMIT 150
