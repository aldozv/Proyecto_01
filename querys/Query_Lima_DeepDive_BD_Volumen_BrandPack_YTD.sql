-- Deep dive BD Lima: volumen HL Beer+Rtds por gerencia vigente x brand pack agrupado, Ene-Oct 2025 y 2026
select c.sales_region_name as gerencia, substr(cast(v.__partition_column as string),1,4) as anio, case when d.brand_name in ('Pilsen Fresh','Pilsen Callao Fresh') then concat('Pilsen Fresh ', m.pack)
       when d.brand_name = 'Corona Cero' then concat('Corona Cero ', m.pack)
       when d.brand_name = 'Cusqueña Cero Trigo' then concat('Cusqueña Cero ', m.pack)
       when d.brand_name = 'Flying Fish' then concat('Flying Fish ', m.pack)
       when m.brand_pack in ('Golden 620 RB','Golden 650 RB') then 'Golden 6XX'
       when m.brand = 'P.Callao' then concat('Pilsen Callao ', m.pack)
       else m.brand_pack end as bp, sum(v.sales_volume_official) as hl
from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.sold_to_customer_short_code
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = v.product_short_code
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product d on d.product_short_code = v.product_short_code
where cast(v.__partition_column as string) in ('202501','202502','202503','202504','202505','202506','202507','202508','202509','202510',
                '202601','202602','202603','202604','202605','202606','202607','202608','202609','202610')
  and v.invoice_date between '2025-01-01' and '2026-10-31' and v.invoice_commercial_flag = 1 and c.sales_area_name = 'PE Dir Lima' and c.sales_region_name like 'PE Ger P1%' and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
group by 1,2,3
limit 5000
