-- SKUs en quiebre por CD x brand_pack, YTD'26 (Ene-Oct). Complemento de Query_OOS_DeepDive_GV_CD_BrandPack_Mensual.sql.
-- skus_oos_list = codigos SAP separados por coma; se explotan y se cruzan con dm_material para el nombre.
with s as (
    select distinct v.distribution_center_code as centro_id, v.brand_pack_name as brand_pack, trim(x) as material_id
    from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
    lateral view explode(split(v.out_of_stock_product_list, ',')) e as x
    where v.period between '202601' and '202610'
    and v.active_flag = 1
    and v.out_of_stock_hours > 0
    and v.distribution_center_code in ('BK43','BK68','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
    and dayofweek(v.out_of_stock_date) <> 1
)
select s.centro_id, s.brand_pack, s.material_id, max(m.product_name) as nombre
from s
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product m
    on ltrim('0', m.product_short_code) = ltrim('0', s.material_id)
group by 1, 2, 3
order by 1, 2, 3
limit 5000
