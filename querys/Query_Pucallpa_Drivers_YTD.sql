-- GV Pucallpa: drivers del volumen Beer+Rtds YTD Ene-Oct por anio. Grano interno cliente-mes.
-- POCs activos (HL>0), POC-mes, dias de compra (proxy de frecuencia), brand-packs distintos.
WITH cm AS (
  SELECT CAST(SUBSTR(v.mes,1,4) AS INT) AS anio, v.mes, v.cliente_id, c.centro,
    COALESCE(c.supervisor,'Sin supervisor') AS supervisor, COALESCE(c.unidad_negocio_revenue_volumen_meta,'Sin clasificar') AS canal,
    SUM(v.hl) AS hl,
    COUNT(DISTINCT CASE WHEN v.hl > 0 THEN v.fecha_venta END) AS dias_compra,
    COUNT(DISTINCT CASE WHEN v.hl > 0 THEN CONCAT(m.marca,'|',COALESCE(r.pack,'')) END) AS bpacks
  FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
  LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku r ON v.material_id = r.sku
  WHERE v.mes BETWEEN '202101' AND '202610' AND c.gerencia = 'PE Ger P4 Pucall Hco' AND v.indicadores_comerciales = 1 AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10 AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
  GROUP BY 1,2,3,4,5,6
)
SELECT anio, centro, supervisor, canal,
  COUNT(DISTINCT cliente_id) AS pocs, COUNT(1) AS poc_mes, SUM(hl) AS hl,
  SUM(dias_compra) AS dias_compra, SUM(bpacks) AS bpacks,
  GROUPING(centro)*4 + GROUPING(supervisor)*2 + GROUPING(canal) AS gid
FROM cm WHERE hl > 0
GROUP BY GROUPING SETS ((anio),(anio,centro),(anio,supervisor),(anio,canal),(anio,centro,canal))
