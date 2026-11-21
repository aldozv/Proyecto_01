-- DAS Sell Out Centro Oriente, YTD Ene-Oct 2023-2026, por categoria (Beer+Rtds y Nabs aparte; sin San Mateo ni Marketplace).
WITH base AS (
  SELECT SUBSTR(v.mes,1,4) AS anio, c.gerencia, v.estratificacion AS estrat,
         CASE WHEN v.estratificacion IN ('Cervezas','Licores') THEN '1 Beer'
              WHEN v.estratificacion = 'Ready To Drink' THEN '2 Rtds'
              ELSE '3 Nabs' END AS cat,
         v.hl
  FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
  JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c ON v.cliente_id = c.cliente_id
  LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku b ON v.material_id = b.sku
  WHERE v.mes BETWEEN '202301' AND '202610' AND SUBSTR(v.mes,5,2) <= '10'
    AND v.indicadores_comerciales = 1 AND c.direccion = 'PE Dir Centro Orient'
    AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
    AND COALESCE(b.marca,'') <> 'San Mateo'
)
SELECT anio, gerencia, cat, estrat, SUM(hl) AS hl
FROM base
GROUP BY GROUPING SETS ((anio, gerencia, cat), (anio, cat, estrat), (anio, cat))
ORDER BY 1,2,3,4
