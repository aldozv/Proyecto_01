-- Volumen MTD (1-18 Oct) 2026 vs mismo periodo 2025, Beer+Rtds, Centro Oriente.
-- Grano: gerencia x CD x canal x categoria x marca x brand_pack. Gerencia/CD/canal desde dm_cliente (regla vigente).
SELECT
  c.gerencia,
  c.centro_id,
  c.centro,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal,
  CASE WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer' ELSE 'Rtds' END AS categoria,
  v.marca AS marca,
  COALESCE(m.brand_pack, 'Sin mapear') AS brand_pack,
  SUM(CASE WHEN v.mes = '202510' THEN v.hl ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN v.mes = '202610' THEN v.hl ELSE 0 END) AS hl_cy
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.material_id = m.material_id
WHERE v.mes IN ('202510','202610')
  AND (v.fecha_venta BETWEEN '2025-10-01' AND '2025-10-18' OR v.fecha_venta BETWEEN '2026-10-01' AND '2026-10-18')
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4,5,6,7
