/* Deep dive Single Serve x24 (revenue_maestro_sku.`Agrupador (Tipo 2.0)` = 'SS x 24') en DSD ON Centro Oriente.
   Venta Beer+Rtds YTD Ene-Oct 2023-2026 por gerencia, subcanal, marca, pack y SKU. Atribucion vigente (dm_cliente). */
WITH cli AS (
  SELECT c.cliente_id, REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv, COALESCE(c.subcanal, 'Sin subcanal') AS subcanal
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  WHERE c.direccion = 'PE Dir Centro Orient'
    AND c.unidad_negocio_revenue_volumen_meta IN ('DSD ON', 'High End')
)
SELECT cli.gv, cli.subcanal, r.marca, r.pack, v.material_id,
  SUM(CASE WHEN v.mes LIKE '2023%' THEN v.hl ELSE 0 END) AS hl_23,
  SUM(CASE WHEN v.mes LIKE '2024%' THEN v.hl ELSE 0 END) AS hl_24,
  SUM(CASE WHEN v.mes LIKE '2025%' THEN v.hl ELSE 0 END) AS hl_25,
  SUM(CASE WHEN v.mes LIKE '2026%' THEN v.hl ELSE 0 END) AS hl_26,
  SUM(CASE WHEN v.mes LIKE '2025%' THEN v.nr ELSE 0 END) AS nr_25,
  SUM(CASE WHEN v.mes LIKE '2026%' THEN v.nr ELSE 0 END) AS nr_26,
  SUM(CASE WHEN v.mes LIKE '2025%' THEN v.descuento ELSE 0 END) AS dscto_25,
  SUM(CASE WHEN v.mes LIKE '2026%' THEN v.descuento ELSE 0 END) AS dscto_26,
  SUM(CASE WHEN v.mes LIKE '2025%' THEN v.caja_fisica ELSE 0 END) AS cf_25,
  SUM(CASE WHEN v.mes LIKE '2026%' THEN v.caja_fisica ELSE 0 END) AS cf_26
FROM slv_maz_dataexperience_peru_dm.dm_venta v
JOIN cli ON v.cliente_id = cli.cliente_id
JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id = r.sku
WHERE v.mes IN ('202301','202302','202303','202304','202305','202306','202307','202308','202309','202310',
                '202401','202402','202403','202404','202405','202406','202407','202408','202409','202410',
                '202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  AND r.`Agrupador (Tipo 2.0)` = 'SS x 24'
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, 2, 3, 4, 5
