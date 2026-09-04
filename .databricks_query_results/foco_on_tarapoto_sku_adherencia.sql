WITH elegibles_by_material AS (
  SELECT a.material_id, count(distinct a.cliente_id) AS clientes_elegibles
  FROM slv_maz_dataexperience_peru_dm.dm_promocion a
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = a.abreviacion_sap AND e.proyecto = 'promos'
  INNER JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = a.cliente_id
  WHERE e.listado = 'Foco ON Oriente'
    AND a.mes = 202608
    AND a.estado = 'R'
    AND c.gerencia = 'PE Ger P4 Tarapoto'
  GROUP BY a.material_id
),
venta_by_material AS (
  SELECT p.material_id,
         count(distinct v.cliente_id) AS clientes_adheridos,
         sum(v.hl) AS HL,
         sum(v.descuento) AS DSCTO
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  INNER JOIN slv_maz_dataexperience_peru_dm.dm_promocion p
    ON v.promocion_id = p.promocion_id AND v.cliente_id = p.cliente_id AND v.material_id = p.material_id
  INNER JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
    ON e.abreviacion_sap = p.abreviacion_sap AND e.proyecto = 'promos'
  WHERE e.listado = 'Foco ON Oriente'
    AND v.direccion = 'PE Dir Centro Orient'
    AND v.gerencia = 'PE Ger P4 Tarapoto'
    AND v.mes = 202608
    AND v.agrupador = 'Venta'
    AND v.indicadores_comerciales = 1
  GROUP BY p.material_id
)
SELECT
  el.material_id,
  m.nombre AS sku,
  d.marca,
  d.pack_xxx AS formato,
  el.clientes_elegibles,
  COALESCE(vn.clientes_adheridos, 0) AS clientes_adheridos,
  ROUND(COALESCE(vn.clientes_adheridos, 0) / el.clientes_elegibles * 100, 1) AS adherencia_pct,
  COALESCE(vn.HL, 0) AS HL,
  COALESCE(vn.DSCTO, 0) AS DSCTO
FROM elegibles_by_material el
LEFT JOIN venta_by_material vn ON vn.material_id = el.material_id
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material m ON m.material_id = el.material_id
LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d ON d.sku = el.material_id
ORDER BY HL DESC
