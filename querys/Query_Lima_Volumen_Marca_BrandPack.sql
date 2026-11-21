-- Lima: volumen Beer+Rtds (HL) por gerencia vigente (dm_cliente) x brand x brand_pack x anio, Ene-Oct 2023-2026.
-- Marca y brand pack desde gld_maz_sales_portfolio_pe.pe_portfolio_material (mismo maestro que Brand
-- Distribution, mas limpio que dm_venta.marca que trae variantes de mayusculas y sabores).
SELECT c.gerencia, COALESCE(m.brand,'Sin mapear') AS brand, COALESCE(m.brand_pack,'Sin mapear') AS brand_pack,
       SUBSTR(v.mes,1,4) AS anio, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m ON v.material_id = m.material_id
WHERE (v.mes BETWEEN '202301' AND '202310' OR v.mes BETWEEN '202401' AND '202410' OR v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610')
  AND c.direccion = 'PE Dir Lima'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
