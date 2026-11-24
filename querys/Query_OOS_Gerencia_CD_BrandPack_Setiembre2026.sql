-- Analisis de stock-outs (OOS en BEES) por Gerencia x CD x Brand_pack, setiembre 2026.
-- Misma metodologia que Query_OOS_Gerencia_CD_BrandPack_Agosto2026.sql (ver ese archivo para el
-- detalle de cada decision); solo cambia el mes (mes = '202609').
-- Alcance: Cervezas + Licores + Ready To Drink (mismo criterio que Brand Distribution / Mix).
-- Fuente: dev_onep_fact_critical_items_summary_24h_brand_pack_gold (ver BITACORA_TABLAS.md).
--
-- Decisiones heredadas de la prueba de agosto (confirmadas por el usuario, 2026-09-08):
-- - Corte: matriz cruzada Gerencia x CD x Brand_pack (no SKU individual).
-- - Orden: hl_perdido (hl_so_brand_pack) desc -- venta estimada perdida por el quiebre.
-- - Filtro activo_en_cd = 1 (evita ruido de brand_pack no vendidos en ese CD).
-- - Gerencia = CD -> GV DOMINANTE (aproximacion, no atribucion exacta). PE Ger P4 DA Jun Puc queda
--   fuera: no opera CD propio.
-- - SJ01 (Planta San Juan) EXCLUIDO: es planta, no CD de reparto a POC.
-- - BK31 (San Benedicto I) EXCLUIDO de GV Tarapoto (pedido puntual del usuario, 2026-09-08).
-- - brand_pack sin material_id: join por PREFIJO de marca contra el maestro de portfolio, con la
--   excepcion manual de "P.Fresh" (Pilsen Fresh, sub-linea de P.Callao).
--
-- "26 dias flat": se EXCLUYEN los domingos (dayofweek = 1 en Spark, 1=domingo...7=sabado), bajo la
-- hipotesis de negocio -- aun NO validada contra venta real de dm_venta -- de que el domingo no hay
-- demanda real en BEES. Setiembre 2026 tiene 4 domingos (6, 13, 20, 27) -> 30 - 4 = 26 dias.
with brands as (
    select distinct brand, estratificacion
    from brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material
    where estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
),
base as (
    select
        v.distribution_center_code as centro_id,
        v.brand_pack_name as brand_pack,
        coalesce(b.brand, case when v.brand_pack_name ilike 'P.Fresh%' then 'P.Callao (Pilsen Fresh)' end) as brand,
        v.out_of_stock_hours as horas_oos_brand_pack,
        v.in_stock_hours as horas_prendidas_brand_pack,
        v.available_hours as horas_disponibles,
        v.lost_sales_volume_hl as hl_so_brand_pack
    from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
    left join brands b
        on v.brand_pack_name ilike concat(b.brand, '%')
        or v.brand_pack_name ilike concat(replace(b.brand, chr(39), ''), '%')
    where v.period = '202609'
    and v.active_flag = 1
    and v.distribution_center_code in ('BK43','BK68','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
    and (b.brand is not null or v.brand_pack_name ilike 'P.Fresh%')
    and dayofweek(v.out_of_stock_date) <> 1
)
select
    case
        when centro_id in ('SJ90','SJ93','SJ97') then 'PE Ger P4 Pucall Hco'
        when centro_id in ('BK43','BK68','SJ86','SJ87') then 'PE Ger P4 Huancay Ch'
        when centro_id in ('SJ91') then 'PE Ger P4 Iquitos'
        when centro_id in ('SJ92','SJ94','SJ95') then 'PE Ger P4 Tarapoto'
    end as gerencia_dominante,
    centro_id,
    brand,
    brand_pack,
    sum(horas_oos_brand_pack) as horas_oos,
    sum(horas_prendidas_brand_pack) as horas_prendidas,
    sum(horas_disponibles) as horas_disponibles_mes,
    round(sum(horas_prendidas_brand_pack) / nullif(sum(horas_disponibles), 0), 4) as pct_uptime,
    round(sum(hl_so_brand_pack), 2) as hl_perdido
from base
group by 1, 2, 3, 4
order by hl_perdido desc
limit 1000
