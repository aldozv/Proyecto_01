-- Evolutivo mensual de la Pilsen Callao 305 x24 retornable (material 15421, "PILSEN CALLAO 305ML RT 24X1")
-- por CD de la GV Pucallpa (SJ90 Huanuco, SJ93 Tingo Maria, SJ97 Pucallpa) + stock out en BEES.
-- Venta: dm_venta, CD y gerencia vigentes del cliente (dm_cliente). Ene'23 a Nov'26 MTD (corte d-1 = 09-nov).
-- OOS: brand_pack 'P.Callao 305 RB' (skus_brand_pack_list = 15421), activo_en_cd = 1, sin domingos.
--      Datos disponibles desde 2025. Uptime = SUM(horas prendidas) / SUM(horas disponibles).
-- No incluye la variante Fresh 305 RT 24X1 (material 23550, brand_pack 'P.Fresh 305 RB').

-- [1] Venta
select cast(v.__partition_column as string) as mes, c.distribution_center_code as centro_id,
  sum(v.billed_sales_boxes_quantity) as cf,
  sum(v.sales_volume_official) as hl
from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.sold_to_customer_short_code = c.customer_short_code
where cast(v.__partition_column as string) between '202301' and '202611'
  and v.invoice_date <= date'2026-11-09'
  and v.invoice_commercial_flag = 1
  and c.sales_region_name = 'PE Ger P4 Pucall Hco'
  and c.distribution_center_code in ('SJ90','SJ93','SJ97')
  and v.product_short_code = '15421'
group by 1, 2
order by 1, 2
limit 1000;

-- [2] Stock out
select v.period as mes, v.distribution_center_code as centro_id,
  count(distinct v.out_of_stock_date) as dias,
  sum(v.out_of_stock_hours) as horas_oos,
  sum(v.available_hours) as horas_disp,
  sum(v.in_stock_hours) / nullif(sum(v.available_hours), 0) as pct_uptime
from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
where v.period between '202501' and '202611'
  and v.out_of_stock_date <= date'2026-11-09'
  and v.active_flag = 1
  and v.distribution_center_code in ('SJ90','SJ93','SJ97')
  and v.brand_pack_name = 'P.Callao 305 RB'
  and dayofweek(v.out_of_stock_date) <> 1
group by 1, 2
order by 1, 2
limit 1000;
