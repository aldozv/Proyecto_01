-- YTD (Ene-Set) 2026 vs 2025, solo categoria Beer (Cervezas + Licores), por brand_pack, HL.
-- Direccion Centro Oriente via dm_cliente (regla vigente: atribucion por cliente actual).
SELECT
  COALESCE(m.brand_pack, 'Sin mapear') AS brand_pack,
  SUM(CASE WHEN v.mes BETWEEN '202501' AND '202509' THEN v.hl ELSE 0 END) AS hl_ly,
  SUM(CASE WHEN v.mes BETWEEN '202601' AND '202609' THEN v.hl ELSE 0 END) AS hl_cy
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.material_id = m.material_id
WHERE (v.mes BETWEEN '202501' AND '202509' OR v.mes BETWEEN '202601' AND '202609')
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores')
GROUP BY COALESCE(m.brand_pack, 'Sin mapear')
ORDER BY SUM(CASE WHEN v.mes BETWEEN '202601' AND '202609' THEN v.hl ELSE 0 END) DESC
