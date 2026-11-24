-- Deep dive GV Pucallpa: HL Beer+Rtds y POCs compradores por CD x supervisor x canal (dm_cliente vigente), sin SJ01.
-- Periodos: YTD25/YTD26 = Ene-Oct, MTD25/MTD26 = 1-22 Nov.
select case when cast(v.__partition_column as string) between '202501' and '202510' then 'YTD25' when cast(v.__partition_column as string) between '202601' and '202610' then 'YTD26'
            when v.invoice_date between '2025-11-01' and '2025-11-22' then 'MTD25' when v.invoice_date between '2026-11-01' and '2026-11-22' then 'MTD26' end as periodo,
  c.distribution_center_code as centro_id, coalesce(c.sales_subregion_name,'Sin supervisor') as supervisor, coalesce(c.business_unit_target_volume,'Sin clasificar') as canal,
  sum(v.sales_volume_official) as hl, count(distinct case when v.sales_volume_official > 0 then v.sold_to_customer_short_code end) as pocs
from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on v.sold_to_customer_short_code = c.customer_short_code
where cast(v.__partition_column as string) between '202501' and '202611' and cast(v.__partition_column as string) not in ('202512') and v.invoice_date <= '2026-11-22'
  and c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01' and v.invoice_commercial_flag = 1
  and v_p.product_line in ('Cervezas','Licores','Ready To Drink')
  and not (cast(v.__partition_column as string) = '202511' and v.invoice_date > '2025-11-22')
group by 1,2,3,4 order by 1,2,3,4 limit 2000
