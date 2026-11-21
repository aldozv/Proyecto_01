-- Direccion Lima: volumen Beer+Rtds (HL) por gerencia vigente x anio x marca x brand_pack, Ene-Oct 2023-2026.
-- Marca normalizada igual que Query_CentroOriente_Marca_CD_Categoria_Mensual.sql. brand_pack desde
-- pe_portfolio_material (join por material_id). Alimenta las slides de marcas/brandpacks de Informe_Overview_Lima.html.
SELECT
  c.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CASE
    WHEN UPPER(v.marca) LIKE 'MIKES%' THEN 'Mikes'
    WHEN UPPER(v.marca) = 'GOLDEN' THEN 'Golden'
    WHEN UPPER(v.marca) = 'CRISTAL (PERU)' THEN 'Cristal'
    WHEN UPPER(v.marca) LIKE 'CUSQUEÑA%' THEN 'Cusqueña'
    WHEN UPPER(v.marca) LIKE 'CORONA%' OR UPPER(v.marca) LIKE 'CORONITA%' THEN 'Corona'
    WHEN UPPER(v.marca) = 'PILSEN CALLAO FRESH' THEN 'Pilsen Callao'
    ELSE v.marca
  END AS marca,
  COALESCE(m.brand_pack, 'Sin brand_pack') AS brand_pack,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON v.material_id = m.material_id
WHERE (v.mes BETWEEN '202301' AND '202310' OR v.mes BETWEEN '202401' AND '202410'
       OR v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610')
  AND c.direccion = 'PE Dir Lima'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
