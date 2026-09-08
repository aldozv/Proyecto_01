-- Cobertura por pack, historico mensual Ene-Ago 2025 vs Ene-Ago 2026, Direccion Centro Oriente.
-- Extiende Query_Coberturas.sql (foto de un solo mes, jun-2026) a serie mensual comparable YoY.
-- Acotado a los 49 packs identificados en ese analisis (top ranking por clientes en jun-2026) para
-- mantener el volumen manejable -- si se necesita historico de un pack fuera de esa lista, agregarlo
-- a la tupla de abajo.
-- Universo (denominador de cobertura) se recalcula por mes: cada mes tiene su propia base de
-- clientes activos, no se reusa un solo universo fijo como en la version de un mes.
WITH universo_mes AS (
  SELECT v.mes, COUNT(DISTINCT v.cliente_id) AS total_clientes
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    ON v.cliente_id = c.cliente_id
  WHERE v.mes BETWEEN '202501' AND '202608'
    AND SUBSTR(v.mes,5,2) BETWEEN '01' AND '08'
    AND v.indicadores_comerciales = 1
    AND c.direccion IN ('PE Dir Centro Orient')
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY v.mes
)
SELECT
  s.marca,
  s.marca_gpa,
  s.pack,
  s.segmento,
  s.`Agrupador (Tipo)`,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  COUNT(DISTINCT v.cliente_id) AS clientes,
  u.total_clientes AS universo_beer,
  ROUND(COUNT(DISTINCT v.cliente_id) * 100.0 / u.total_clientes, 1) AS cobertura_pct,
  ROUND(SUM(v.hl), 1) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s
  ON CAST(v.material_id AS STRING) = s.sku
INNER JOIN universo_mes u
  ON u.mes = v.mes
WHERE v.mes BETWEEN '202501' AND '202608'
  AND SUBSTR(v.mes,5,2) BETWEEN '01' AND '08'
  AND v.indicadores_comerciales = 1
  AND c.direccion IN ('PE Dir Centro Orient')
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
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
