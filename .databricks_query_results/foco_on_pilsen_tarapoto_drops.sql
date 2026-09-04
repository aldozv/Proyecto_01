SELECT
  marca,
  pack,
  count(distinct cliente_id) AS clientes,
  avg(drop_dia_m1) AS drop_prom_m1,
  avg(total_cajas_m1) AS cajas_prom_cliente_m1,
  avg(hl_mtd) AS hl_prom_mtd_check,
  avg(total_hl_m1) AS hl_prom_m1_check
FROM slv_maz_dataexperience_peru_revenue.revenue_dev_vw_rev_maestro_drops_brandpack
WHERE direccion = 'PE Dir Centro Orient'
  AND gerencia = 'PE Ger P4 Tarapoto'
  AND marca = 'P.Callao'
GROUP BY marca, pack
ORDER BY clientes DESC
LIMIT 100
