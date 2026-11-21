-- Top 5 Brand Pack de LATAS (pack LIKE '%CAN%') mas vendidas, promedio mensual de los ultimos 3
-- meses cerrados (Jun-Ago 2026), solo categoria Cervezas, a nivel Gerencia (sin CD).
-- Complemento de Query_Top5_BrandPack_Latas_Cerveza_GerenciaCD.sql.
WITH base AS (
  SELECT
    c.gerencia,
    v.mes,
    v.marca,
    r.pack,
    SUM(v.hl) AS hl,
    SUM(v.caja_fisica) AS caja_fisica
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    ON v.cliente_id = c.cliente_id
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r
    ON v.material_id = r.sku
  WHERE v.mes BETWEEN '202606' AND '202608'
    AND c.direccion = 'PE Dir Centro Orient'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion = 'Cervezas'
    AND r.pack LIKE '%CAN%'
  GROUP BY c.gerencia, v.mes, v.marca, r.pack
),
agg AS (
  SELECT
    gerencia,
    marca,
    pack,
    CONCAT(marca, ' ', pack) AS brand_pack,
    SUM(hl) / 3.0 AS avg_hl_mensual,
    SUM(caja_fisica) / 3.0 AS avg_cf_mensual
  FROM base
  GROUP BY gerencia, marca, pack
),
ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY gerencia ORDER BY avg_hl_mensual DESC) AS ranking
  FROM agg
)
SELECT gerencia, ranking, marca, pack, brand_pack, avg_hl_mensual, avg_cf_mensual
FROM ranked
WHERE ranking <= 5
ORDER BY gerencia, ranking
