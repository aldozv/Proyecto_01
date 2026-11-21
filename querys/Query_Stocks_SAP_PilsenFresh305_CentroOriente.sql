-- =============================================================================
-- STOCK FISICO SAP (Libre Utilizacion) — Pilsen Callao Fresh 305ml x24 (matnr 23550)
-- Por CD Centro Oriente
-- =============================================================================
-- Version simplificada de querys/Query_Stocks_SAP.sql: solo stock fisico (MCHB,
-- tabla de estado vigente), SIN la cascada de pedidos/entregas/reservas (VBBE/RESB
-- son logs CDC de 653M filas y no admiten poda de particion al filtrar por
-- material -> muy lentos). Usar esta version cuando solo se necesite "el stock",
-- no la disponibilidad final (ATP) comprometida.
-- Fecha ejecucion: 2026-09-08. Foto de stock = inicio del dia de hoy (batch SAP,
-- MCHB carga ~1pm Peru).
-- =============================================================================

WITH
conv AS (
  SELECT CAST(m.matnr AS INT) AS matnr,
         MAX(m.umrez)  AS umrez,
         MAX(ma.mtart) AS mtart
  FROM brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_marm m
  JOIN brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_mara ma
    ON ma.matnr = m.matnr AND ma.op_ind <> 'D'
  WHERE m.op_ind <> 'D' AND m.meinh = 'UMV' AND CAST(m.matnr AS INT) = 23550
  GROUP BY CAST(m.matnr AS INT)
),

txt AS (
  SELECT CAST(matnr AS INT) AS matnr, MAX(maktx) AS descripcion
  FROM brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_makt
  WHERE op_ind <> 'D' AND spras = 'S' AND CAST(matnr AS INT) = 23550
  GROUP BY CAST(matnr AS INT)
),

stock AS (
  SELECT CAST(b.matnr AS INT) AS matnr, TRIM(b.werks) AS werks,
         SUM(b.clabs) AS clabs_base
  FROM brewdat_uc_maz_prod.slv_maz_supply_sap_pr3.copecac_mchb b
  WHERE b.op_ind <> 'D' AND b.clabs <> 0
    AND CAST(b.matnr AS INT) = 23550
    AND TRIM(b.werks) IN ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
  GROUP BY CAST(b.matnr AS INT), TRIM(b.werks)
)

SELECT
  s.werks                              AS Centro,
  t.descripcion                        AS Descripcion,
  ROUND(s.clabs_base / c.umrez, 0)     AS Stock_Disp_CA
FROM stock s
JOIN conv c ON c.matnr = s.matnr
LEFT JOIN txt t ON t.matnr = s.matnr
WHERE c.mtart = 'FERT'
ORDER BY Stock_Disp_CA DESC;
