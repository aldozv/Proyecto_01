-- Cobertura por pack: marca + tipo_envase + volumen (usando revenue_maestro_sku)
-- CORREGIDO 2026-09-07: (1) comentario de la linea 1 tenia un solo guion (error de sintaxis
-- SQL); (2) direccion sale de dm_cliente (c.direccion), no de dm_venta (v.direccion) -- misma
-- regla vigente desde 2026-09-04 que ya se aplico al dashboard de Volumen (ver CLAUDE.md).
  WITH universo AS
  (
    SELECT COUNT(DISTINCT v.cliente_id) AS total_clientes
    FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
    INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
      ON v.cliente_id = c.cliente_id
    WHERE v.mes = 202606
      AND v.indicadores_comerciales = 1
      --AND c.direccion IN ('PE Dir Centro Orient','PE Dir Lima','PE Dir Norte','PE Dir Sur')
      AND c.direccion IN ('PE Dir Centro Orient')
      AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  )
  SELECT
    s.marca,
    s.marca_gpa,
    s.pack,                -- ej: '630 RB', '355 CAN', '310 NRB'
    s.segmento,            -- Core, Premium, Super Premium, Value
    s.`Agrupador (Tipo)`,  -- agrupación comercial (Core 6xx, Latas 355, etc.)
    COUNT(DISTINCT v.cliente_id) AS clientes,
    u.total_clientes AS universo_beer,
    ROUND(COUNT(DISTINCT v.cliente_id) * 100.0 / u.total_clientes, 1) AS cobertura_pct,
    ROUND(SUM(v.hl), 0) AS hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    ON v.cliente_id = c.cliente_id
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s
    ON CAST(v.material_id AS STRING) = s.sku
  CROSS JOIN universo u
  WHERE v.mes = 202606
    AND v.indicadores_comerciales = 1
    --AND c.direccion IN ('PE Dir Centro Orient','PE Dir Lima','PE Dir Norte','PE Dir Sur')
    AND c.direccion IN ('PE Dir Centro Orient')
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY ALL
  ORDER BY clientes DESC
  LIMIT 50