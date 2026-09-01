-- Uptime / quiebres de stock (OOS) por brand_pack y Centro de Distribucion (CD)
-- Acotado a los CDs que reparten a Direccion Centro Oriente (via dm_cliente.centro_id).
-- Lista confirmada por el usuario 2026-08-31 (13 CDs, de un universo inicial de 22): se excluyen
-- BK34, BK36, BK46, BK49, BK60, BK77, BK79, BK80 -- no pertenecen a la operacion de Centro Oriente
-- (BK60 = "HUB LURIN MKP", almacen de Marketplace en Lima, no CD de portafolio Backus; los otros
-- 7 son CDs de otras regionales) -- y BK71 (Chanchamayo), codigo legado sin actividad real desde
-- 2017, reemplazado por SJ87. Ver detalle completo en CLAUDE.md / BITACORA_TABLAS.md.
-- OJO: un mismo CD reparte a mas de una gerencia -> este corte es a nivel CD/direccion,
-- no se puede desglosar de forma limpia por gerencia individual (ver BITACORA_TABLAS.md).
-- Alcance de categoria: solo Cervezas + Licores + Ready To Drink (mismo criterio que Brand
-- Distribution, confirmado con usuario 2026-08-31).
-- OJO: esta tabla NO tiene material_id, solo `brand_pack` (marca + sub-marca/sabor + presentacion,
-- ej "Cusqueña Malta 310 NRB"). Un join EXACTO contra pe_portfolio_material.brand_pack falla para
-- ~36 valores (sub-marcas/sabores como "Cusqueña Malta/Trigo/Dorada/Cero/Quinua" que no existen
-- como brand_pack en el maestro, "Mikes" sin apostrofe vs "Mike's" en el maestro, formatos KEGS
-- nuevos) -- ver detalle en BITACORA_TABLAS.md. Se resuelve con un join por PREFIJO de `brand`
-- (marca base, sin sub-marca/sabor/presentacion) contra la lista de marcas Cervezas/Licores/RTD;
-- deja solo 18 brand_pack sin matchear, todos de categorias fuera de alcance (Guarana/Viva=
-- Gaseosas, Maltin Power=Malta) salvo "P.Fresh" -> ES Cervezas (confirmado con usuario 2026-08-31):
-- es "Pilsen Fresh", sub-linea de P.Callao (brand="P.Callao", brand_detailed="Pilsen Fresh" en el
-- maestro), pero en esta tabla de OOS aparece con el prefijo "P.Fresh" en vez de "P.Callao" -> no
-- lo agarra ni el match exacto ni el de prefijo por brand, requiere excepcion manual.
with brands as (
    select distinct brand, estratificacion
    from brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material
    where estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
)
select
    v.mes,
    v.out_of_stock_date,
    v.centro_id,
    v.brand_pack,
    coalesce(b.brand, case when v.brand_pack ilike 'P.Fresh%' then 'P.Callao (Pilsen Fresh)' end) as brand,
    coalesce(b.estratificacion, case when v.brand_pack ilike 'P.Fresh%' then 'Cervezas' end) as estratificacion,
    v.cant_skus_brand_pack,
    v.horas_oos_brand_pack,
    v.horas_prendidas_brand_pack,
    v.pct_horas_oos_brand_pack,
    v.pct_uptime_brand_pack,
    v.hl_so_brand_pack,
    v.hl_pv_promedio_bp,
    v.skus_en_quiebre
from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
left join brands b
    on v.brand_pack ilike concat(b.brand, '%')
    or v.brand_pack ilike concat(replace(b.brand, chr(39), ''), '%')
where v.mes = '202608'
and v.activo_en_cd = 1
and v.centro_id in ('BK31','BK43','BK68',
                   'SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
and (b.brand is not null or v.brand_pack ilike 'P.Fresh%')
order by v.out_of_stock_date, v.centro_id, v.brand_pack
