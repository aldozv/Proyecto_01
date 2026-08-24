-- Uptime / quiebres de stock (OOS) por brand_pack y Centro de Distribucion (CD)
-- Acotado a los 22 centros que reparten a Direccion Centro Oriente (via dm_cliente.centro_id).
-- OJO: un mismo CD reparte a mas de una gerencia -> este corte es a nivel CD/direccion,
-- no se puede desglosar de forma limpia por gerencia individual (ver BITACORA_TABLAS.md).
select
    mes,
    out_of_stock_date,
    centro_id,
    brand_pack,
    cant_skus_brand_pack,
    horas_oos_brand_pack,
    horas_prendidas_brand_pack,
    pct_horas_oos_brand_pack,
    pct_uptime_brand_pack,
    hl_so_brand_pack,
    hl_pv_promedio_bp,
    skus_en_quiebre
from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold`
where mes = '202608'
and activo_en_cd = 1
and centro_id in ('BK31','BK34','BK36','BK43','BK46','BK49','BK60','BK68','BK71','BK77','BK79','BK80',
                   'SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
order by out_of_stock_date, centro_id, brand_pack
