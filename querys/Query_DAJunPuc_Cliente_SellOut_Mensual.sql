-- Por Cliente - Sell Out, gerencia PE Ger P4 DA Jun Puc. Basado en Query_DAS_Sell_Out.sql
-- (ya existente en el proyecto), adaptado: acotado a DA Jun Puc (gerencia vigente de
-- dm_das_cliente, no dm_das_venta -- mismo criterio que el resto del proyecto), rango mensual
-- completo (no solo el mes en curso), y con desglose por categoria via
-- pe_portfolio_material.estratificacion (mismo campo/regla que el resto del dashboard:
-- Beer=Cervezas+Licores, Rtds=Ready To Drink, Nabs=Gaseosas+Agua+Maltas sin San Mateo) --
-- reemplaza el intento anterior con revenue_material_agrupacion.grupo_id, que no sirve para
-- desglosar por categoria sin duplicar (grano material x grupo, tags solapados).
-- Excluye Ucayali Beer (recien empieza a reportar Sell Out en ago'26, volumen marginal) para
-- combinar 1:1 con los 6 distribuidores ya usados en el segmento Brand Distribution.
SELECT
  f.mes,
  CASE
    WHEN m.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN m.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN m.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  CASE
    WHEN f.razon_social = 'Distribuidora Maximo Sanchez S.R.L.' THEN 'INVERSIONES DMS S.R.L.'
    WHEN f.razon_social = 'Central Peru S.A.' THEN 'P & A Logistic S.A.C. - Huancayo'
    WHEN f.razon_social = 'Bustamante Medina, Jose Edilberto' THEN 'P & A Logistic S.A.C. Piura'
    WHEN f.razon_social = 'Distribuidora Wong Ruiz S.A.C' THEN 'P & A Logistic S.A.C. Piura'
    WHEN f.razon_social = 'Transportes Hermanos Linares S.A.C' THEN 'Distribuidora Vacri'
    WHEN f.razon_social = 'Direor S.A.C.' THEN 'Dismar Cinco Sociedad De Responsabilidad Limitada Huánuco'
    WHEN f.razon_social = 'Dismar Cinco Sociedad De Responsabilidad Limitada' THEN 'Dismar Cinco Sociedad De Responsabilidad Limitada Huánuco'
    ELSE f.razon_social
  END AS razon_social,
  SUM(f.hl) AS hl
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta f
INNER JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente c
  ON f.cliente_id = c.cliente_id
INNER JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON m.material_id = f.material_id
WHERE f.mes BETWEEN '202501' AND '202609'
  AND c.gerencia = 'PE Ger P4 DA Jun Puc'
  AND m.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (m.estratificacion = 'Agua' AND m.brand = 'San Mateo')
  AND f.indicadores_comerciales = 1
  AND f.razon_social <> 'UCAYALI BEER'
GROUP BY ALL
ORDER BY ALL
