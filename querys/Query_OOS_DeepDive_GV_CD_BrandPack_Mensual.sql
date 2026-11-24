-- Deep dive de quiebres de stock (OOS en BEES) Centro Oriente: GV x CD x brand_pack x mes, Ene'25-Oct'26
-- (YTD'26 vs YTD'25, Ene-Oct a mes cerrado). Pedido del usuario 2026-11-15.
-- Misma metodologia que Query_OOS_Gerencia_CD_BrandPack_*: Beer+Rtds por prefijo de marca (+ P.Fresh),
-- activo_en_cd = 1, domingos fuera, SJ01 (planta) y BK31 fuera, GV = CD -> GV dominante (DA Jun Puc sin CD).
-- La tabla solo trae filas en dias con quiebre: el % del mes en quiebre se calcula afuera como
-- horas_oos / (24 x dias operativos del mes). hl_so NO se usa como cifra principal (no es dimensionable).
-- Gap de fuente: SJ92 (Moyobamba) sin filas en Jun y Jul'26; el dashboard excluye esos CD-mes en ambos anios.
with brands as (
    select distinct brand
    from brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material
    where estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
),
base as (
    select distinct v.period as mes, v.out_of_stock_date as out_of_stock_date, v.distribution_center_code as centro_id, v.brand_pack_name as brand_pack,
        v.out_of_stock_hours as horas_oos_brand_pack, v.max_out_of_stock_days_quantity as max_length_of_time_days, v.out_of_stock_product_list as skus_oos_list
    from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
    left join brands b
        on v.brand_pack_name ilike concat(b.brand, '%')
        or v.brand_pack_name ilike concat(replace(b.brand, chr(39), ''), '%')
    where v.period between '202501' and '202610'
    and cast(substr(v.period, 5, 2) as int) <= 10
    and v.active_flag = 1
    and v.distribution_center_code in ('BK43','BK68','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
    and (b.brand is not null or v.brand_pack_name ilike 'P.Fresh%')
    and v.brand_pack_name not ilike 'Cristalina%'  -- agua (dm_material: estratificacion Agua); el prefijo 'Cristal' la arrastraba
    and dayofweek(v.out_of_stock_date) <> 1
)
select
    case
        when centro_id in ('SJ90','SJ93','SJ97') then 'Pucall Hco'
        when centro_id in ('BK43','BK68','SJ86','SJ87') then 'Huancay Ch'
        when centro_id = 'SJ91' then 'Iquitos'
        when centro_id in ('SJ92','SJ94','SJ95') then 'Tarapoto'
    end as gv,
    centro_id,
    brand_pack,
    mes,
    round(sum(horas_oos_brand_pack), 1) as horas_oos,
    count(distinct case when horas_oos_brand_pack > 0 then out_of_stock_date end) as dias_quiebre,
    max(max_length_of_time_days) as max_dias_evento,
    count(*) as filas
from base
group by 1, 2, 3, 4
order by 2, 3, 4
limit 20000
