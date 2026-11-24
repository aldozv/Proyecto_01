---- BRAND DISTRO DAS -- DA Jun Puc, solo SELLOUT, agregado a nivel distribuidor ----
-- dm_das_cliente.cliente_id es grano POC final (miles de codigos por distribuidor, confirmado
-- 2026-09-08: 7 distribuidores reales en DA Jun Puc, de 113 a 7746 cliente_id cada uno) -- por
-- eso se filtra temprano por el cliente_id de esos 7 distribuidores (gerencia vigente de
-- dm_das_cliente) y se agrega solo a nivel "sociedad" (nuestro cliente directo), sin bajar a
-- POC/zona_comisional. Version anterior filtraba gerencia recien al final, corriendo las window
-- functions sobre TODO el universo DAS (todas las direcciones) para 21 meses -- exedia el limite
-- de tamano de resultado inline (26MB) por la explosion de filas a grano POC.
with das_clientes_dajunpuc as (
    SELECT cliente_id, sociedad
    FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente
    WHERE gerencia = 'PE Ger P4 DA Jun Puc'
),
tmp_ventas_skuxpoc as (
    SELECT
        v.mes,
        v.fecha_venta,
        v.cliente_id,
        v.material_id,
        SUM(v.caja_fisica) as hl
    FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
    INNER JOIN das_clientes_dajunpuc dc ON dc.cliente_id = v.cliente_id
    WHERE v.mes BETWEEN '202401' AND '202609'
    GROUP BY ALL
),
tmp_skuxpoc_mayor_0 AS (
    SELECT *,
        SUM(hl) OVER (PARTITION BY mes, cliente_id, material_id ORDER BY fecha_venta ASC) AS hl_acum
    FROM tmp_ventas_skuxpoc
    QUALIFY SUM(hl) OVER (PARTITION BY mes, cliente_id, material_id) > 0
),
tmp_skuxpoc_mayor_0_acum AS (
    SELECT *,
        CASE
            WHEN hl_acum > 0 AND
                COALESCE(LAG(hl_acum) OVER (PARTITION BY mes, cliente_id, material_id ORDER BY fecha_venta ASC), 0) <= 0
            THEN 1
            ELSE 0
        END AS neteo
    FROM tmp_skuxpoc_mayor_0
),
tmp_skuxpoc_mayor_0_acum_brand_distro AS (
    SELECT *,
        CASE
            WHEN fecha_venta = MAX(CASE WHEN neteo = 1 THEN fecha_venta END) OVER (PARTITION BY mes, cliente_id, material_id)
            THEN 1
            ELSE 0
        END AS flag_brand_distro
    FROM tmp_skuxpoc_mayor_0_acum
)
SELECT
    a.mes,
    dc.sociedad AS razon_social,
    SUM(flag_brand_distro) AS BrandDistro
FROM tmp_skuxpoc_mayor_0_acum_brand_distro a
INNER JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m ON m.material_id = a.material_id
INNER JOIN das_clientes_dajunpuc dc ON dc.cliente_id = a.cliente_id
WHERE flag_brand_distro = 1
  AND m.brand_category IN ('Megabrand','RTDs','Beer NO Megabrand')
GROUP BY ALL
ORDER BY ALL
