-- Cobertura por pack, historico mensual Ene-Ago 2025 vs Ene-Ago 2026, Direccion Centro Oriente.
-- Extiende Query_Coberturas.sql (foto de un solo mes, jun-2026) a serie mensual comparable YoY.
-- Acotado a los 49 packs identificados en ese analisis (top ranking por clientes en jun-2026) para
-- mantener el volumen manejable -- si se necesita historico de un pack fuera de esa lista, agregarlo
-- a la tupla de abajo.
-- Universo (denominador de cobertura) se recalcula por mes: cada mes tiene su propia base de
-- clientes activos, no se reusa un solo universo fijo como en la version de un mes.
WITH universo_mes AS (
  SELECT cast(v.__partition_column as string) as mes, COUNT(DISTINCT v.sold_to_customer_short_code) AS total_clientes
  FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
    ON v.sold_to_customer_short_code = c.customer_short_code
  WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202608'
    AND SUBSTR(cast(v.__partition_column as string),5,2) BETWEEN '01' AND '08'
    AND v.invoice_commercial_flag = 1
    AND c.sales_area_name IN ('PE Dir Centro Orient')
    AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY cast(v.__partition_column as string)
)
SELECT
  s.marca,
  s.marca_gpa,
  s.pack,
  s.segmento,
  s.`Agrupador (Tipo)`,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  COUNT(DISTINCT v.sold_to_customer_short_code) AS clientes,
  u.total_clientes AS universo_beer,
  ROUND(COUNT(DISTINCT v.sold_to_customer_short_code) * 100.0 / u.total_clientes, 1) AS cobertura_pct,
  ROUND(SUM(v.sales_volume_official), 1) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON v.sold_to_customer_short_code = c.customer_short_code
INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s
  ON CAST(v.product_short_code AS STRING) = s.sku
INNER JOIN universo_mes u
  ON u.mes = cast(v.__partition_column as string)
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202608'
  AND SUBSTR(cast(v.__partition_column as string),5,2) BETWEEN '01' AND '08'
  AND v.invoice_commercial_flag = 1
  AND c.sales_area_name IN ('PE Dir Centro Orient')
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink')
  AND (s.marca, s.marca_gpa, s.pack) IN (
    ('P.Callao','P.Callao','630 RB'),
    ('Cusqueña','Cusqueña Trigo','620 RB'),
    ('Cristal','Cristal','650 RB'),
    ('P.Callao','P.Callao','473 CAN'),
    ('San Juan','San Juan','620 RB'),
    ('Cusqueña','Cusqueña Malta','620 RB'),
    ('P.Callao','P.Fresh','473 CAN'),
    ('Mike''s','Mikes Maracuya','355 CAN'),
    ('San Juan','San Juan','355 CAN'),
    ('Cusqueña','Cusqueña Trigo','473 CAN'),
    ('P.Callao','P.Callao','355 CAN'),
    ('Mike''s','Mikes Limon','355 CAN'),
    ('Corona','Corona','330 NRB'),
    ('Mike''s','Mikes Fresa','355 CAN'),
    ('Cristal','Cristal','355 CAN'),
    ('Cristal','Cristal','473 CAN'),
    ('Corona','Corona','210 NRB'),
    ('Cusqueña','Cusqueña Trigo','355 CAN'),
    ('Golden','Golden','473 CAN'),
    ('Cusqueña','Cusqueña Malta','355 CAN'),
    ('P.Callao','P.Fresh','355 CAN'),
    ('Cusqueña','Cusqueña Malta','473 CAN'),
    ('Mike''s','Mikes Arandanos','355 CAN'),
    ('Mike''s','Mikes Manzana','355 CAN'),
    ('Golden','Golden','650 RB'),
    ('Flying Fish','Flying Fish','355 CAN'),
    ('Corona','Corona','473 CAN'),
    ('Cusqueña','Cusqueña Malta','310 NRB'),
    ('P.Callao','P.Callao','305 RB'),
    ('Corona','Corona Cero','355 NRB'),
    ('Cusqueña','Cusqueña Cero','355 CAN'),
    ('Cusqueña','Cusqueña Cero','310 NRB'),
    ('P.Callao','P.Callao','269 CAN'),
    ('Cusqueña','Cusqueña Quinua','473 CAN'),
    ('Golden','Golden','355 CAN'),
    ('P.Callao','P.Callao','1000 RB'),
    ('Stella Artois','Stella Artois','330 NRB'),
    ('Cusqueña','Cusqueña Trigo','310 NRB'),
    ('Cusqueña','Cusqueña Trigo','310 RB'),
    ('P.Callao','P.Callao','305 NRB'),
    ('P.Callao','P.Fresh','305 NRB'),
    ('Cristal','Cristal','305 RB'),
    ('Cusqueña','Cusqueña','355 CAN'),
    ('Cusqueña','Cusqueña','620 RB'),
    ('Budweiser','Budweiser','355 CAN'),
    ('Cristal','Cristal','1000 RB'),
    ('Budweiser','Budweiser','600 RB'),
    ('Golden','Golden','269 CAN'),
    ('P.Callao','P.Callao Mult','355 CAN')
  )
GROUP BY ALL
ORDER BY marca, pack, anio, mes_num
