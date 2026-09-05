SELECT
  CAST(SUBSTR(b.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(b.mes,5,2) AS INT) AS mes_num,
  SUM(b.flag_brand_distro) AS bd
FROM brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
INNER JOIN brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m
  ON b.material_id = m.material_id
WHERE b.gerencia = 'PE Ger P4 DA Jun Puc'
  AND b.tipo = 'SELLOUT'
  AND b.mes BETWEEN '202401' AND '202609'
  AND m.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY CAST(SUBSTR(b.mes,1,4) AS INT), CAST(SUBSTR(b.mes,5,2) AS INT)
ORDER BY anio, mes_num
