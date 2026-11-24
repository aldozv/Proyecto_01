-- v7 lamina BD: stock outs de los 5 SKUs pedidos por el usuario, Ene-Oct 2025 y 2026, CDs de Centro Oriente
select v.brand_pack_name as brand_pack, substr(v.period,1,4) as anio,
  count(distinct v.distribution_center_code) as cds, count(distinct v.out_of_stock_date) as dias_con_oos,
  sum(v.out_of_stock_hours) as h_oos, sum(v.lost_sales_volume_hl) as hl_perdido
from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
where (v.period between '202501' and '202510' or v.period between '202601' and '202610')
and v.active_flag = 1
and v.distribution_center_code in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
and v.brand_pack_name in ('San Juan 355 CAN','Cristal 355 CAN','Cristal 650 RB','Golden 473 CAN','Corona 210 NRB')
group by 1,2
limit 100
