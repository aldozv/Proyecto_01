-- Deep dive GV Pucallpa: SKUs con quiebre (OOS en BEES) por CD: YTD'26 (Ene-Oct), MTD Nov'26 (1 al 24, d-1) y HOY26 (25-nov, parcial: hasta la ultima corrida de la tabla).
-- Fuente: dev_onep_fact_critical_items_summary_24h_brand_pack_gold (grano dia x CD x brand_pack, filas solo en dias con quiebre).
-- skus_oos_list = codigos SAP en quiebre ese dia; se explotan por SKU.
-- Horas OOS = horas del brand_pack en los dias que el SKU estuvo en la lista (la tabla no trae horas por SKU).
-- Alcance: CDs de la GV (SJ90 Huanuco, SJ93 Tingo Maria, SJ97 Pucallpa), activo_en_cd = 1, sin domingos.
-- Nombre y categoria del SKU se cruzan despues con el detalle de venta del deep dive (sku = codigo - nombre),
-- quedando solo Beer+Rtds. (dm_material sin permiso de lectura al 23-11-2026.)
with s as (
    select
        case when v.out_of_stock_date = date'2026-11-25' then 'HOY26' when v.period = '202611' then 'MTD26' else 'YTD26' end as periodo,
        v.distribution_center_code as centro_id, v.brand_pack_name as brand_pack, v.out_of_stock_date as out_of_stock_date,
        v.out_of_stock_hours as h_oos, v.available_hours as h_disp,
        regexp_replace(trim(x), '^0+', '') as material_id
    from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
    lateral view explode(split(v.out_of_stock_product_list, ',')) e as x
    where v.period between '202601' and '202611'
      and v.out_of_stock_date <= date'2026-11-25'
      and v.active_flag = 1
      and v.out_of_stock_hours > 0
      and v.distribution_center_code in ('SJ90', 'SJ93', 'SJ97')
      and dayofweek(v.out_of_stock_date) <> 1
)
select
    s.periodo,
    case s.centro_id when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' end as cd,
    s.material_id,
    max(s.brand_pack) as brand_pack,
    count(distinct s.out_of_stock_date) as dias_oos,
    sum(s.h_oos) as h_oos,
    max(s.h_disp) as h_disp  -- en HOY26: horas del dia ya medidas
from s
where s.material_id <> ''
group by 1, 2, 3
order by 1, 2, 6 desc
limit 5000
