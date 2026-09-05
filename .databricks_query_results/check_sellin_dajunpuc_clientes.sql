SELECT
  b.cliente_id,
  c.nombre,
  c.centro,
  COUNT(DISTINCT b.mes) AS meses_con_dato,
  MIN(b.mes) AS mes_min,
  MAX(b.mes) AS mes_max,
  SUM(b.flag_brand_distro) AS suma_flag_total
FROM brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON b.cliente_id = c.cliente_id
WHERE b.gerencia = 'PE Ger P4 DA Jun Puc'
  AND b.tipo = 'SELLIN'
  AND b.mes BETWEEN '202401' AND '202609'
GROUP BY b.cliente_id, c.nombre, c.centro
ORDER BY suma_flag_total DESC
LIMIT 50
