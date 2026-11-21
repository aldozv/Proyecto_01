/* DSD ON Centro Oriente: POCs compradores Beer+Rtds y POCs que compran SS x24, y HL/NR de SS x24, por gerencia y mes
   Ene'23-Oct'26 (para cobertura de SS x24, tendencia mensual y precio NR/HL). POC comprador = HL > 0 en el mes. */
WITH cli AS (
  SELECT c.cliente_id, REPLACE(c.gerencia, 'PE Ger P4 ', '') AS gv
  FROM slv_maz_dataexperience_peru_dm.dm_cliente c
  WHERE c.direccion = 'PE Dir Centro Orient'
    AND c.unidad_negocio_revenue_volumen_meta IN ('DSD ON', 'High End')
),
cm AS (
  SELECT v.mes, cli.gv, v.cliente_id,
    SUM(v.hl) AS hl,
    SUM(CASE WHEN r.`Agrupador (Tipo 2.0)` = 'SS x 24' THEN v.hl ELSE 0 END) AS hl_ss24,
    SUM(CASE WHEN r.`Agrupador (Tipo 2.0)` = 'SS x 24' THEN v.nr ELSE 0 END) AS nr_ss24
  FROM slv_maz_dataexperience_peru_dm.dm_venta v
  JOIN cli ON v.cliente_id = cli.cliente_id
  LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id = r.sku
  WHERE v.mes >= '202301' AND v.mes <= '202610'
    AND v.indicadores_comerciales = 1
    AND v.estratificacion IN ('Cervezas', 'Licores', 'Ready To Drink')
  GROUP BY 1, 2, 3
)
SELECT mes, gv,
  SUM(CASE WHEN hl > 0 THEN 1 ELSE 0 END) AS pocs,
  SUM(CASE WHEN hl_ss24 > 0 THEN 1 ELSE 0 END) AS pocs_ss24,
  SUM(hl) AS hl, SUM(hl_ss24) AS hl_ss24, SUM(nr_ss24) AS nr_ss24
FROM cm
GROUP BY 1, 2
ORDER BY 1, 2
