-- Cobertura por pack: marca + tipo_envase + volumen (usando revenue_maestro_sku)
-- CORREGIDO 2026-09-07: (1) comentario de la linea 1 tenia un solo guion (error de sintaxis
-- SQL); (2) direccion sale de dm_cliente (c.direccion), no de dm_venta (v.direccion) -- misma
-- regla vigente desde 2026-09-04 que ya se aplico al dashboard de Volumen (ver CLAUDE.md).
  WITH universo AS
  (
    SELECT COUNT(DISTINCT v.sold_to_customer_short_code) AS total_clientes
    FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
    INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
      ON v.sold_to_customer_short_code = c.customer_short_code
    WHERE cast(v.__partition_column as string) = 202606
      AND v.invoice_commercial_flag = 1
      --AND c.direccion IN ('PE Dir Centro Orient','PE Dir Lima','PE Dir Norte','PE Dir Sur')
      AND c.sales_area_name IN ('PE Dir Centro Orient')
      AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  )
  SELECT
    s.marca,
    s.marca_gpa,
    s.pack,                -- ej: '630 RB', '355 CAN', '310 NRB'
    s.segmento,            -- Core, Premium, Super Premium, Value
    s.`Agrupador (Tipo)`,  -- agrupación comercial (Core 6xx, Latas 355, etc.)
    COUNT(DISTINCT v.sold_to_customer_short_code) AS clientes,
    u.total_clientes AS universo_beer,
    ROUND(COUNT(DISTINCT v.sold_to_customer_short_code) * 100.0 / u.total_clientes, 1) AS cobertura_pct,
    ROUND(SUM(v.sales_volume_official), 0) AS hl
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
    ON v.sold_to_customer_short_code = c.customer_short_code
  INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s
    ON CAST(v.product_short_code AS STRING) = s.sku
  CROSS JOIN universo u
  WHERE cast(v.__partition_column as string) = 202606
    AND v.invoice_commercial_flag = 1
    --AND c.direccion IN ('PE Dir Centro Orient','PE Dir Lima','PE Dir Norte','PE Dir Sur')
    AND c.sales_area_name IN ('PE Dir Centro Orient')
    AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY ALL
  ORDER BY clientes DESC
  LIMIT 50