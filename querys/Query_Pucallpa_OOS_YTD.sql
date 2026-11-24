-- CDs de la GV Pucallpa (SJ90, SJ93, SJ97): uptime BEES Ene-Oct por anio x brand_pack. Datos disponibles desde 2025.
-- Metodologia de Query_OOS_Gerencia_CD_BrandPack_*: Beer+Rtds por prefijo de marca, activo_en_cd = 1, sin domingos.
-- hl_so se trae pero NO es dimensionable: estima para P.Callao 630 en SJ97 muchas veces lo vendido por la GV.
WITH brands AS (
  SELECT DISTINCT brand FROM brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material
  WHERE estratificacion IN ('Cervezas','Licores','Ready To Drink')
), bp AS (
  SELECT DISTINCT v.brand_pack_name as brand_pack
  FROM brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
  JOIN brands b ON v.brand_pack_name ILIKE CONCAT(b.brand,'%') OR v.brand_pack_name ILIKE CONCAT(REPLACE(b.brand,CHR(39),''),'%')
  WHERE v.period BETWEEN '202501' AND '202610' AND v.distribution_center_code IN ('SJ90','SJ93','SJ97')
)
SELECT SUBSTR(v.period,1,4) AS anio, v.distribution_center_code as centro_id, v.brand_pack_name as brand_pack,
  SUM(v.out_of_stock_hours) AS h_oos, SUM(v.in_stock_hours) AS h_on, SUM(v.available_hours) AS h_disp, SUM(v.lost_sales_volume_hl) AS hl_so
FROM brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack v
WHERE v.period BETWEEN '202501' AND '202610' AND CAST(SUBSTR(v.period,5,2) AS INT) <= 10
  AND v.active_flag = 1 AND v.distribution_center_code IN ('SJ90','SJ93','SJ97') AND DAYOFWEEK(v.out_of_stock_date) <> 1
  AND (v.brand_pack_name IN (SELECT brand_pack FROM bp) OR v.brand_pack_name ILIKE 'P.Fresh%')
GROUP BY 1,2,3
