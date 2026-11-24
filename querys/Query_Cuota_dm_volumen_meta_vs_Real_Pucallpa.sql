-- Cuota de volumen (dm_volumen_meta) vs real, GV Pucallpa, por categoria (estratificacion de dm_material). Exploracion 23.11.26.
-- Grano de la cuota: mes x cliente x material (fecha = dia 1 del mes); 'accion' = metodo de split por POC (HL SUGERIDO / HL HOMOGENEO).
with q as (
  select q.mes, q.cliente_id, q.material_id, q.hl, q.zona_comisional, q.gerencia as ger_cuota
  from brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_volumen_meta q
  where q.mes in ('202610','202611') and q.direccion like '%Centro Orient%'
), r as (
  select cast(v.__partition_column as string) as mes, v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, v.sales_volume_official as hl, v_p.product_line as estratificacion
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
  where cast(v.__partition_column as string) = '202610' and v.invoice_commercial_flag = 1
)
select 'CUOTA' as tipo, q.mes, coalesce(m.product_line, 'sin_material') as estrat,
  sum(case when c.sales_region_name = 'PE Ger P4 Pucall Hco' then q.hl end) as hl_pucallpa_dmcliente,
  sum(case when q.ger_cuota = 'PE Ger P4 Pucall Hco' then q.hl end) as hl_pucallpa_gercuota,
  count(distinct case when c.sales_region_name = 'PE Ger P4 Pucall Hco' then q.zona_comisional end) as zonas,
  count(distinct case when c.sales_region_name = 'PE Ger P4 Pucall Hco' then c.sales_subregion_name end) as sups
from q left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = q.cliente_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m on m.product_short_code = q.material_id
group by 1,2,3
union all
select 'REAL', r.mes, coalesce(r.estratificacion,'?'), sum(case when c.sales_region_name = 'PE Ger P4 Pucall Hco' then r.hl end), null, null, null
from r join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = r.cliente_id
where c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01'
group by 1,2,3
order by 2,3,1 limit 100
