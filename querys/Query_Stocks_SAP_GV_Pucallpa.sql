-- Stock SAP (cascada ZSMGEN_STOCK_DISP) para los 3 CDs de la GV Pucallpa: SJ97 Pucallpa, SJ90 Huanuco, SJ93 Tingo Maria.
-- Basado en querys/Query_Stocks_SAP.sql (Data Engineering Peru, Javier, 2026-07-09); leer ahi la mecanica y advertencias.
-- Cambios (2026-11-24, workspace nuevo):
--   * Catalogo brewdat_uc_maz_prod -> brewdat_uc_delta_maz_prod (las copecac_* viven ahi).
--   * copecac_marm/mara/makt sin permiso -> conversion, nombre y categoria desde pe_product.
--   * copecac_resb no esta en el workspace nuevo -> reservas = 0 (en CDs de producto terminado casi siempre era 0).
--   * Almacenes: el analogo de IQ01/IQ24 de Iquitos en cada CD (xx01 = producto terminado, xx24). Pendiente
--     confirmar con logistica (40/41/98 quedan fuera).
-- Frescura validada 24-nov: MCHB con cargas durante el dia (ultima ~20:00 Lima), ya no solo foto de la manana.
WITH
conv AS (
  -- copecac_marm/mara/makt sin permiso en el workspace nuevo -> conversion y nombre desde pe_product (ALZ 4.0):
  -- base_uom_quantity = unidades por caja (= marm.umrez), base_uom_volume = volumen unitario en cm3 (= mara.volum).
  SELECT CAST(p.product_short_code AS INT) AS matnr, MAX(p.base_uom_quantity) AS umrez, MAX(p.base_uom_volume) AS volum,
         MAX(p.product_name) AS descripcion, MAX(p.product_line) AS categoria
  FROM brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product p
  GROUP BY CAST(p.product_short_code AS INT)
),
stock AS (
  SELECT CAST(b.matnr AS INT) AS matnr, TRIM(b.werks) AS werks, SUM(b.clabs) AS clabs_base, MAX(b.target_apply_ts) AS ult_carga
  FROM brewdat_uc_delta_maz_prod.slv_maz_supply_sap_pr3.copecac_mchb b
  WHERE b.op_ind <> 'D' AND b.clabs <> 0
    AND TRIM(b.werks) IN ('SJ90', 'SJ93', 'SJ97')
    AND TRIM(b.lgort) IN ('HN01', 'HN24', 'TI01', 'TI24', 'UL01', 'UL24')
  GROUP BY CAST(b.matnr AS INT), TRIM(b.werks)
),
vbbe_open AS (
  SELECT CAST(matnr AS INT) AS matnr, TRIM(werks) AS werks, vbtyp, omeng, vbeln
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY mandt, vbeln, posnr, etenr ORDER BY target_apply_ts DESC, header__change_seq DESC) AS rn
    FROM brewdat_uc_delta_maz_prod.slv_maz_sales_sap_pr3.copecac_vbbe
    WHERE werks IN ('SJ90', 'SJ93', 'SJ97')
  )
  WHERE rn = 1 AND op_ind IN ('I', 'U')
),
req AS (
  SELECT matnr, werks,
         SUM(CASE WHEN vbtyp = 'J' THEN omeng ELSE 0 END) AS entregas_base,
         SUM(CASE WHEN vbtyp = 'C' THEN omeng ELSE 0 END) AS pedidos_base,
         COUNT(DISTINCT CASE WHEN vbtyp = 'C' THEN vbeln END) AS n_pedidos
  FROM vbbe_open
  GROUP BY matnr, werks
)
SELECT
  s.matnr AS Material,
  c.descripcion AS Descripcion,
  c.categoria AS Categoria,
  s.werks AS Centro,
  ROUND(s.clabs_base / c.umrez, 0) AS Stock_Disp,
  ROUND(COALESCE(rq.entregas_base, 0) / c.umrez, 0) AS Cant_Entrega_Pend,
  ROUND((s.clabs_base - COALESCE(rq.entregas_base, 0)) / c.umrez, 0) AS Total_Disponible,
  COALESCE(rq.n_pedidos, 0) AS Cant_Pedidos,
  ROUND(COALESCE(rq.pedidos_base, 0) / c.umrez, 0) AS Cantidad_En_Pedidos,
  ROUND((s.clabs_base - COALESCE(rq.entregas_base, 0) - COALESCE(rq.pedidos_base, 0)) / c.umrez, 0) AS Disponible_Final,
  (s.clabs_base / c.umrez) * ((c.umrez * c.volum) / 100000) AS HL_Stock,
  s.ult_carga AS Ult_Carga
FROM stock s
JOIN conv c ON c.matnr = s.matnr
LEFT JOIN req rq ON rq.matnr = s.matnr AND rq.werks = s.werks
WHERE c.categoria IN ('Cervezas', 'Licores', 'Ready To Drink', 'Gaseosas', 'Agua', 'Maltas')
ORDER BY s.werks, Stock_Disp DESC
LIMIT 3000
