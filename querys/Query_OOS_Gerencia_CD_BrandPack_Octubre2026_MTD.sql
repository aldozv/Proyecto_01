-- Analisis de stock-outs (OOS en BEES) por Gerencia x CD x Brand_pack, octubre 2026 MTD.
-- Misma metodologia que Query_OOS_Gerencia_CD_BrandPack_Agosto2026.sql y ..._Setiembre2026.sql
-- (ver el de agosto para el detalle de cada decision); cambia el mes (mes = '202610') y el corte.
-- Alcance: Cervezas + Licores + Ready To Drink. Fuente: dev_onep_fact_critical_items_summary_24h_brand_pack_gold.
--
-- MTD a d-1 (convencion de CLAUDE.md): el dia en curso NO entra. Refrescada el 2026-10-20 (corte 19-oct; antes 07-oct, corte 06-oct). El dia en curso
-- trae horas parciales por fila, por eso queda fuera.
-- Para refrescar el avance mas adelante, mover la fecha tope (out_of_stock_date <= d-1) y volver a correr.
--
-- Decisiones heredadas de la prueba de agosto/setiembre:
-- - Corte matriz Gerencia x CD x Brand_pack (no SKU individual); orden por hl_perdido desc.
-- - Filtro activo_en_cd = 1.
-- - Gerencia = CD -> GV DOMINANTE (aproximacion). PE Ger P4 DA Jun Puc fuera: no opera CD propio.
-- - SJ01 (Planta San Juan) EXCLUIDO: es planta, no CD de reparto a POC.
-- - BK31 (San Benedicto I) EXCLUIDO de GV Tarapoto (pedido puntual del usuario, 2026-09-08).
-- - brand_pack sin material_id: join por PREFIJO de marca, con excepcion manual de "P.Fresh".
--
-- "Dias operativos": se EXCLUYEN los domingos (dayofweek = 1 en Spark, 1=domingo...7=sabado), hipotesis de
-- negocio aun NO validada contra venta real de dm_venta. Octubre MTD: 01 al 19-oct con 3 domingos (04, 11, 18-oct)
-- -> 16 dias operativos. OJO: los HL totales NO son comparables con meses completos de 26 dias;
-- comparar por HL por dia operativo y por % uptime.
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
    where v.mes = '202610'
    and v.out_of_stock_date <= date'2026-10-19'
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
