-- Volumen (HL) Beer+Rtds por gerencia x CD x supervisor x marca x pack, Direccion Centro Oriente, mensual Ene'23-Oct'26.
-- Igual que Query_CentroOriente_Volumen_BeerRtds_Gerencia_BrandPack_Mensual_2023_2026.sql + c.centro_id y c.supervisor.
-- Gerencia, CD y supervisor son los VIGENTES del cliente (dm_cliente): todo el historico se atribuye a su asignacion actual.
-- Marca de dm_material (dm_venta.marca es NULL antes de 2024); pack de revenue_maestro_sku. Agrupacion de marcas en el informe (BITACORA).
-- Usado en la v3 de Presentacion_Volumen_CO_2023_2026 (brand pack por GV x CD y GV x supervisor), 17.11.26.
SELECT
  v.mes,
  c.gerencia,
  c.centro_id,
  COALESCE(c.supervisor, 'Sin supervisor') AS supervisor,
  COALESCE(m.marca, 'Sin marca') AS marca,
  COALESCE(r.pack, 'Sin mapear') AS pack,
  ROUND(SUM(v.hl), 3) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m
  ON v.material_id = m.material_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
  ON v.material_id = r.sku
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes, c.gerencia, c.centro_id, COALESCE(c.supervisor, 'Sin supervisor'), COALESCE(m.marca, 'Sin marca'), COALESCE(r.pack, 'Sin mapear')
ORDER BY 1, 2, 3, 4, 5, 6
LIMIT 300000
