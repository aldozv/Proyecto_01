WITH foco_on_clientes AS (
  SELECT DISTINCT v.cliente_id
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
)
SELECT
  CASE WHEN v.cliente_id IN (SELECT cliente_id FROM foco_on_clientes) THEN 'Foco ON (cohorte agosto 2026)' ELSE 'Resto (no Foco ON)' END AS segmento,
  v.mes,
  sum(v.hl) AS HL,
  count(distinct v.cliente_id) AS clientes
FROM slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN slv_maz_dataexperience_peru_dm.dm_cliente c ON c.cliente_id = v.cliente_id
WHERE v.direccion = 'PE Dir Centro Orient'
  AND v.mes IN (202408, 202508)
  AND v.agrupador = 'Venta'
  AND v.indicadores_comerciales = 1
  AND c.unidad_negocio_revenue_volumen_meta = 'DSD ON'
  AND v.estratificacion = 'Cervezas'
GROUP BY segmento, v.mes
ORDER BY segmento, v.mes
