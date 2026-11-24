-- Lima SS deep dive Q1: mes x gerencia x canal x grupo (CR473/BUD355/SS_OTROS/MS) con volumen, precio y descuentos. 2023-01..2026-10
SELECT v.mes, c.gerencia, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') canal, CASE WHEN r.ms_ss IS NULL THEN 'SIN_MAP' WHEN r.ms_ss='SS' AND dm.marca='Cristal (Peru)' AND r.pack='473 CAN' THEN 'CR473' WHEN r.ms_ss='SS' AND dm.marca='Budweiser' AND r.pack='355 CAN' THEN 'BUD355' WHEN r.ms_ss='SS' THEN 'SS_OTROS' ELSE 'MS' END grupo,
 SUM(v.hl) hl, SUM(v.gsi) gsi, SUM(v.excise) excise, SUM(v.descuento) dscto, SUM(v.descuento_promocion) dscto_promo,
 SUM(v.descuento_canal) dscto_canal, SUM(v.descuento_combo) dscto_combo, SUM(v.nr) nr, SUM(v.maco) maco,
 SUM(CASE WHEN v.descuento_promocion<0 OR v.descuento_combo<0 THEN v.hl ELSE 0 END) hl_con_promo,
 COUNT(DISTINCT v.cliente_id) compradores
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id=c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material dm ON v.material_id=dm.material_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id=r.sku
WHERE v.mes BETWEEN '202301' AND '202610' AND c.direccion='PE Dir Lima' AND v.indicadores_comerciales=1 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY 1,2,3,4
LIMIT 20000
