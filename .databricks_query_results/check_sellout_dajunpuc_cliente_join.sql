SELECT
  b.tipo,
  COUNT(DISTINCT b.cliente_id) AS clientes_distintos_bd,
  COUNT(DISTINCT c.cliente_id) AS matcheados_en_dm_cliente,
  SUM(b.flag_brand_distro) AS suma_flag
FROM brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON b.cliente_id = c.cliente_id
WHERE b.gerencia = 'PE Ger P4 DA Jun Puc'
  AND b.mes = '202608'
GROUP BY b.tipo
