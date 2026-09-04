SELECT
  e.listado,
  a.abreviacion_sap,
  a.descripcion,
  a.tipo_mecanica,
  a.escala,
  a.periodo_promo,
  min(a.desde) as vigencia_desde,
  max(a.hasta) as vigencia_hasta,
  count(distinct a.material_id) as n_materiales,
  count(distinct a.cliente_id) as n_clientes,
  count(distinct a.promocion_id) as n_promociones
FROM slv_maz_dataexperience_peru_dm.dm_promocion a
inner join slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas e
  on e.abreviacion_sap = a.abreviacion_sap and e.proyecto = 'promos'
WHERE e.listado IN ('Foco ON Centro','Foco ON Oriente')
  and a.desde >= current_timestamp - interval '6 month'
GROUP BY e.listado, a.abreviacion_sap, a.descripcion, a.tipo_mecanica, a.escala, a.periodo_promo
ORDER BY e.listado, vigencia_desde DESC
