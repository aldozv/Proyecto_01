-- CDs de la GV Pucallpa (SJ90, SJ93, SJ97): uptime BEES Ene-Oct por anio x brand_pack. Datos disponibles desde 2025.
-- Metodologia de Query_OOS_Gerencia_CD_BrandPack_*: Beer+Rtds por prefijo de marca, activo_en_cd = 1, sin domingos.
-- hl_so se trae pero NO es dimensionable: estima para P.Callao 630 en SJ97 muchas veces lo vendido por la GV.
WITH brands AS (
  SELECT DISTINCT brand FROM brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material
  WHERE estratificacion IN ('Cervezas','Licores','Ready To Drink')
), bp AS (
  SELECT DISTINCT v.brand_pack
  FROM delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
  JOIN brands b ON v.brand_pack ILIKE CONCAT(b.brand,'%') OR v.brand_pack ILIKE CONCAT(REPLACE(b.brand,CHR(39),''),'%')
  WHERE v.mes BETWEEN '202501' AND '202610' AND v.centro_id IN ('SJ90','SJ93','SJ97')
)
SELECT SUBSTR(v.mes,1,4) AS anio, v.centro_id, v.brand_pack,
  SUM(v.horas_oos_brand_pack) AS h_oos, SUM(v.horas_prendidas_brand_pack) AS h_on, SUM(v.horas_disponibles) AS h_disp, SUM(v.hl_so_brand_pack) AS hl_so
FROM delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold` v
WHERE v.mes BETWEEN '202501' AND '202610' AND CAST(SUBSTR(v.mes,5,2) AS INT) <= 10
  AND v.activo_en_cd = 1 AND v.centro_id IN ('SJ90','SJ93','SJ97') AND DAYOFWEEK(v.out_of_stock_date) <> 1
  AND (v.brand_pack IN (SELECT brand_pack FROM bp) OR v.brand_pack ILIKE 'P.Fresh%')
GROUP BY 1,2,3
