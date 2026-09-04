WITH elegibles AS (
  SELECT DISTINCT e.listado, a.material_id
  FROM slv_maz_dataexperience_peru_dm.dm_promocion a
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
  WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
    AND a.mes = 202608
    AND a.estado = 'R'
),
vendidos_bajo_promo AS (
  SELECT DISTINCT e.listado, p.material_id
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN slv_maz_dataexperience_peru_dm.dm_promocion p
    ON v.promocion_id = p.promocion_id AND v.cliente_id = p.cliente_id AND v.material_id = p.material_id
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = p.abreviacion_sap AND e.proyecto = 'promos'
  WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
    AND v.direccion = 'PE Dir Centro Orient'
    AND v.mes = 202608
    AND v.agrupador = 'Venta'
    AND v.indicadores_comerciales = 1
),
venta_general_sku AS (
  SELECT v.material_id, sum(v.hl) as hl_total_sku, sum(v.caja_fisica) as cf_total_sku,
         count(distinct v.cliente_id) as clientes_compraron_sku
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  WHERE v.direccion = 'PE Dir Centro Orient'
    AND v.mes = 202608
    AND v.agrupador = 'Venta'
    AND v.indicadores_comerciales = 1
  GROUP BY v.material_id
)
SELECT
  el.listado,
  el.material_id,
  m.nombre AS nombre_sku,
  m.marca,
  m.estado AS estado_material,
  COALESCE(vg.hl_total_sku, 0) AS hl_venta_general_sin_promo,
  COALESCE(vg.cf_total_sku, 0) AS cf_venta_general_sin_promo,
  COALESCE(vg.clientes_compraron_sku, 0) AS clientes_compraron_sin_promo
FROM elegibles el
LEFT JOIN vendidos_bajo_promo vp ON el.listado = vp.listado AND el.material_id = vp.material_id
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material m ON m.material_id = el.material_id
LEFT JOIN venta_general_sku vg ON vg.material_id = el.material_id
WHERE vp.material_id IS NULL
ORDER BY el.listado, el.material_id
