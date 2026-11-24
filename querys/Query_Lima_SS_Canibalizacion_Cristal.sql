-- Lima SS deep dive Q5: Cristal y Pilsen por pack, YTD Ene-Oct 2025 vs 2026, canal DSD OFF vs resto (chequeo de canibalizacion de Cristal 473)
SELECT SUBSTR(v.mes,1,4) anio, dm.marca, r.pack, CASE WHEN c.unidad_negocio_revenue_volumen_meta='DSD OFF' THEN 'DSD OFF' ELSE 'Resto' END canal,
 SUM(v.hl) hl, SUM(v.nr) nr, SUM(v.maco) maco
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id=c.cliente_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material dm ON v.material_id=dm.material_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id=r.sku
WHERE (v.mes BETWEEN '202501' AND '202510' OR v.mes BETWEEN '202601' AND '202610') AND c.direccion='PE Dir Lima' AND v.indicadores_comerciales=1
 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink') AND dm.marca IN ('Cristal (Peru)','Pilsen Callao')
GROUP BY 1,2,3,4 LIMIT 500
