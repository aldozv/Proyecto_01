SELECT
  CAST(SUBSTR(b.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(b.mes,5,2) AS INT) AS mes_num,
  CASE
    WHEN c.customer_name LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.customer_name
  END AS nombre_cliente,
  SUM(b.flag_brand_distro) AS bd
FROM brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
INNER JOIN brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON b.material_id = m.material_id
INNER JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c
  ON b.cliente_id = c.customer_short_code
WHERE b.gerencia = 'PE Ger P4 DA Jun Puc'
  AND b.tipo = 'SELLIN'
  AND b.mes BETWEEN '202401' AND '202609'
  AND m.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY
  CAST(SUBSTR(b.mes,1,4) AS INT), CAST(SUBSTR(b.mes,5,2) AS INT),
  CASE
    WHEN c.customer_name LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.'
    ELSE c.customer_name
  END
ORDER BY anio, mes_num, nombre_cliente
