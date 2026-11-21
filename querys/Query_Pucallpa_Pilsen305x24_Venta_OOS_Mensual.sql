-- Evolutivo mensual de la Pilsen Callao 305 x24 retornable (material 15421, "PILSEN CALLAO 305ML RT 24X1")
-- por CD de la GV Pucallpa (SJ90 Huanuco, SJ93 Tingo Maria, SJ97 Pucallpa) + stock out en BEES.
-- Venta: dm_venta, CD y gerencia vigentes del cliente (dm_cliente). Ene'23 a Nov'26 MTD (corte d-1 = 09-nov).
-- OOS: brand_pack 'P.Callao 305 RB' (skus_brand_pack_list = 15421), activo_en_cd = 1, sin domingos.
--      Datos disponibles desde 2025. Uptime = SUM(horas prendidas) / SUM(horas disponibles).
-- No incluye la variante Fresh 305 RT 24X1 (material 23550, brand_pack 'P.Fresh 305 RB').

-- [1] Venta
select v.mes, c.centro_id,
  sum(v.caja_fisica) as cf,
  sum(v.hl) as hl
from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on v.cliente_id = c.cliente_id
where v.mes between '202301' and '202611'
  and v.fecha_venta <= date'2026-11-09'
  and v.indicadores_comerciales = 1
  and c.gerencia = 'PE Ger P4 Pucall Hco'
  and c.centro_id in ('SJ90','SJ93','SJ97')
  and v.material_id = '15421'
group by 1, 2
order by 1, 2
limit 1000;

-- [2] Stock out
select v.mes, v.centro_id,
  count(distinct v.out_of_stock_date) as dias,
  sum(v.horas_oos_brand_pack) as horas_oos,
  sum(v.horas_disponibles) as horas_disp,
  sum(v.horas_prendidas_brand_pack) / nullif(sum(v.horas_disponibles), 0) as pct_uptime
from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
where v.mes between '202501' and '202611'
  and v.out_of_stock_date <= date'2026-11-09'
  and v.activo_en_cd = 1
  and v.centro_id in ('SJ90','SJ93','SJ97')
  and v.brand_pack = 'P.Callao 305 RB'
  and dayofweek(v.out_of_stock_date) <> 1
group by 1, 2
order by 1, 2
limit 1000;
