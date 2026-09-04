SELECT
  a.mes,
  a.material_id,
  b.nombre AS nombre_sku,
  sum(a.hl) AS HL,
  sum(a.caja_fisica) AS CF,
  count(distinct a.cliente_id) AS clientes
FROM slv_maz_dataexperience_peru_dm.dm_venta a
LEFT JOIN slv_maz_dataexperience_peru_dm.dm_material b ON b.material_id = a.material_id
WHERE a.direccion = 'PE Dir Centro Orient'
  AND a.material_id IN ('6841','23118')
  AND a.mes BETWEEN 202501 AND 202608
  AND a.agrupador = 'Venta'
  AND a.indicadores_comerciales = 1
GROUP BY a.mes, a.material_id, b.nombre
ORDER BY a.material_id, a.mes
