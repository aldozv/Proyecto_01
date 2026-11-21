-- Prueba de analisis de stock-outs (OOS en BEES) por Gerencia x CD x Brand_pack, agosto 2026.
-- Alcance: Cervezas + Licores + Ready To Drink (mismo criterio que Brand Distribution / Mix).
-- Fuente: dev_onep_fact_critical_items_summary_24h_brand_pack_gold (ver BITACORA_TABLAS.md).
--
-- Decisiones confirmadas por el usuario (2026-09-08):
-- - Corte: matriz cruzada Gerencia x CD x Brand_pack (no SKU individual).
-- - Prioridad/orden: hl_perdido (hl_so_brand_pack) desc -- venta estimada perdida por el quiebre.
-- - Filtro activo_en_cd = 1 (evita ruido de brand_pack no vendidos en ese CD).
--
-- Gerencia: esta tabla NO tiene relacion 1:1 CD->gerencia (un CD puede repartir a varias GV), asi
-- que se usa el mapeo CD -> GV DOMINANTE ya validado para Brand Distribution (>98% del volumen de
-- casi todos los CD es de una sola GV) -- ver CLAUDE.md "CD (Centro de Distribucion) / Centro".
-- Es una APROXIMACION, no una atribucion exacta. PE Ger P4 DA Jun Puc queda fuera de este corte
-- porque no opera CD propio (0% de volumen en todos los CD, es canal distribuidor).
--
-- SJ01 (Planta San Juan) se EXCLUYE: no es un CD de reparto a POC, es la planta de produccion
-- (misma ubicacion fisica que SJ97/CD Pucallpa) -- CLAUDE.md advierte explicitamente que mezclar
-- quiebres de stock BEES de una planta con los de un CD de reparto no es comparable.
--
-- brand_pack no tiene material_id: join por PREFIJO de marca base contra el maestro de portfolio
-- (ver BITACORA_TABLAS.md / querys/Query_Sku_Uptime.sql), con la excepcion manual ya validada de
-- "P.Fresh" (Pilsen Fresh, sub-linea de P.Callao, no matchea ni exacto ni por prefijo de brand).
--
-- "26 dias flat" (agregado 2026-09-08): se EXCLUYEN los domingos (dayofweek = 1 en Spark, donde
-- 1=domingo...7=sabado) de la suma, bajo la hipotesis de negocio (no validada aun con dm_venta)
-- de que el domingo no hay demanda real en BEES -> un quiebre ese dia no genera perdida real.
-- Agosto 2026 tiene 5 domingos (2,9,16,23,30) -> 31-5 = 26 dias "planos". Validado puntualmente
-- con Cristal 650 RB en SJ91/Iquitos: HL perdido bajo de 12.646,98 a ~10.901,77 (-13,8%) al quitar
-- los 3 domingos con dato de esa combinacion (2 de los 5 ya faltaban en la tabla fuente para ese
-- brand_pack especifico). Pendiente: confirmar la hipotesis de "cero demanda domingo" contra
-- venta real de dm_venta antes de adoptarla como definitiva.
--
-- BK31 (San Benedicto I/Ate) EXCLUIDO de GV Tarapoto (a pedido del usuario, 2026-09-08) -- sigue
-- siendo CD de Centro Oriente segun CLAUDE.md, pero se pidio no considerarlo en este analisis de
-- OOS puntual. 11 CD activos en el alcance (de los 12 de CLAUDE.md).
with brands as (
    select distinct brand, estratificacion
    from brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material
    where estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
),
base as (
    select
        v.centro_id,
        v.brand_pack,
        coalesce(b.brand, case when v.brand_pack ilike 'P.Fresh%' then 'P.Callao (Pilsen Fresh)' end) as brand,
        v.horas_oos_brand_pack,
        v.horas_prendidas_brand_pack,
        v.horas_disponibles,
        v.hl_so_brand_pack
    from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
    left join brands b
        on v.brand_pack ilike concat(b.brand, '%')
        or v.brand_pack ilike concat(replace(b.brand, chr(39), ''), '%')
    where v.mes = '202608'
    and v.activo_en_cd = 1
    and v.centro_id in ('BK43','BK68','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
    and (b.brand is not null or v.brand_pack ilike 'P.Fresh%')
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
