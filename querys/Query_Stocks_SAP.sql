-- =============================================================================
-- STOCK & DISPONIBILIDAD ATP — Reproducción de la Z ZSMGEN_STOCK_DISP (SAP)
-- =============================================================================
-- Autor      : Data Engineering Peru (Javier) — a pedido de Aldo Zavala (Oriente)
-- Fecha      : 2026-07-09
-- Motor      : Databricks ALZ  ->  python3 lib/dbx.py "<este SQL>"
-- Catalog    : brewdat_uc_maz_prod  (SAP PR3 replicado por BrewDat), visible en ALZ
-- Dominio    : context/schemas/stock_sap.md  (queries QSTK1-QSTK5)
--
-- QUÉ HACE:
--   Reconstruye la cascada de disponibilidad que muestra la transacción SAP
--   ZSMGEN_STOCK_DISP ("verificación de disponibilidad de stock"):
--
--     Stock Disp (Libre Utilización)              <- MCHB.clabs / MARD.labst
--       - Cant. Entrega Pendiente                 <- VBBE (entregas abiertas, vbtyp=J)
--       = Total Disponible
--       - Cantidad en Pedidos (abiertos)          <- VBBE (pedidos abiertos,  vbtyp=C)
--       = Disponible Final
--       - StockReser (reservas)                   <- RESB (reservas abiertas)
--       = CalDisFinal   (el más "ácido": descuenta preventa/compromisos futuros)
--
-- ⚠️ TRAZABILIDAD / LÍMITE CONOCIDO (leer antes de usar los números):
--   1) FRESCURA: la ingesta SAP->Databricks es batch de la mañana (foto inicio-día).
--      MARD carga ~10:01am Perú (= la última MB52 de las 10am), MCHB ~1pm.
--      El STOCK FÍSICO cuadra a esa hora; pero los PEDIDOS/ENTREGAS se acumulan
--      durante el día, por lo que "Disponible Final"/"CalDisFinal" NO coinciden
--      con SAP en vivo. Ej. validado (mat.1565/SJ91): pedidos aquí ~28 CA vs
--      27,191 CA en la foto SAP en vivo. -> estas columnas son REFERENCIALES
--      de inicio de día, no ATP en tiempo real.
--   2) ALCANCE DE ALMACENES: el "Stock Disp" de la Z usa un subconjunto de
--      almacenes (~IQ01 Prod.Terminados), no todos. Aquí, por defecto, se suman
--      TODOS los almacenes del centro. Para acercarse a SAP, descomentar el
--      filtro LGORT (ver CTE 'stock'). Pendiente confirmar el set con logística.
--   3) MAPEO vbtyp C/J pendiente de validar contra una foto SAP del mismo instante.
--
-- CÓMO SE SACÓ:
--   - Unidades en unidad base (botella) -> /marm.umrez (meinh='UMV') = cajas (CA).
--   - HL = cajas * ((umrez * mara.volum) / 100000).
--   - matnr viene con ceros a la izquierda -> CAST(matnr AS INT).
--   - Filtrar op_ind<>'D' (borrado lógico del CDC) en TODA tabla copecac_*.
--   - MARD/MCHB son estado-vigente (sumar directo). VBBE/RESB son CDC append-log
--     -> se reconstruye el estado vigente (último cambio por PK, op_ind IN I/U).
--
-- PARÁMETRO (CENTRO):  el filtro de centro aparece en 4 sitios y DEBEN coincidir:
--   (1) CTE 'stock'  (2) CTE 'vbbe_open'  (3) CTE 'resb_open'  (4) SELECT final.
--   Por defecto = 'SJ91' (Iquitos). El prefiltro en los CTE CDC es OBLIGATORIO por
--   performance (VBBE tiene 653M filas). Nacional -> reemplazar los 4 por el patrón
--   (werks LIKE 'BK%' OR werks LIKE 'SJ%' OR werks LIKE 'AH%') — puede tardar varios min.
-- =============================================================================

WITH
-- (0) Conversión a cajas + volumen unitario (para HL) --------------------------
conv AS (
  SELECT CAST(m.matnr AS INT) AS matnr,
         MAX(m.umrez)  AS umrez,     -- unidades base por caja (UMV)
         MAX(ma.volum) AS volum,     -- volumen unitario (cm3/ml)
         MAX(ma.mtart) AS mtart,     -- tipo de material (FERT = producto terminado)
         MAX(CASE WHEN ma.normt <> 'MARKETPLACE' OR ma.normt IS NULL
                  THEN 'BACKUS' ELSE ma.normt END) AS tipo_material
  FROM brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_marm m
  JOIN brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_mara ma
    ON ma.matnr = m.matnr AND ma.op_ind <> 'D'
  WHERE m.op_ind <> 'D' AND m.meinh = 'UMV'
  GROUP BY CAST(m.matnr AS INT)
),

-- (1) Texto del material (español) --------------------------------------------
txt AS (
  SELECT CAST(matnr AS INT) AS matnr, MAX(maktx) AS descripcion
  FROM brewdat_uc_maz_prod.slv_maz_masterdata_sap_pr3.copecac_makt
  WHERE op_ind <> 'D' AND spras = 'S'
  GROUP BY CAST(matnr AS INT)
),

-- (2) STOCK FÍSICO (Libre Utilización) por material x centro — MCHB (por lote) -
--     Estado-vigente: se suma directo. Solo FERT (producto terminado).
stock AS (
  SELECT CAST(b.matnr AS INT) AS matnr, TRIM(b.werks) AS werks,
         SUM(b.clabs) AS clabs_base            -- libre utilización (unidad base)
  FROM brewdat_uc_maz_prod.slv_maz_supply_sap_pr3.copecac_mchb b
  WHERE b.op_ind <> 'D' AND b.clabs <> 0
    AND TRIM(b.werks) = 'SJ91'   -- <<< CENTRO (1 de 4 sitios a cambiar). Nacional: quitar y ver nota cabecera
    -- Alcance de almacenes: por defecto TODOS. Para acercar a SAP (~IQ01), descomentar:
    AND TRIM(b.lgort) IN ('IQ01','IQ24')
    --AND TRIM(b.lgort) IN ('IQ01','IQ24','IQ16','IQ98','IQ99')
  GROUP BY CAST(b.matnr AS INT), TRIM(b.werks)
),

-- (3) REQUERIMIENTOS SD ABIERTOS — VBBE (CDC -> se reconstruye estado vigente) --
--     vbtyp='J' = entregas en curso ; vbtyp='C' = pedidos de venta abiertos.
vbbe_open AS (
  SELECT CAST(matnr AS INT) AS matnr, TRIM(werks) AS werks, vbtyp, omeng, vbeln
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY mandt, vbeln, posnr, etenr
                              ORDER BY target_apply_ts DESC, header__change_seq DESC) AS rn
    FROM brewdat_uc_maz_prod.slv_maz_sales_sap_pr3.copecac_vbbe
    WHERE werks = 'SJ91'     -- ⚡ REQUISITO PERFORMANCE: prefiltrar el centro EXACTO (VBBE = 653M filas CDC).
                             --    <<< CENTRO (2 de 4). Alinear con los otros. Nacional: LIKE 'BK%' OR LIKE 'SJ%' OR LIKE 'AH%'
  )
  WHERE rn = 1 AND op_ind IN ('I','U')
),
req AS (
  SELECT matnr, werks,
         SUM(CASE WHEN vbtyp = 'J' THEN omeng ELSE 0 END)        AS entregas_base,   -- Cant. Entrega Pendiente
         SUM(CASE WHEN vbtyp = 'C' THEN omeng ELSE 0 END)        AS pedidos_base,     -- Cantidad en Pedidos
         COUNT(DISTINCT CASE WHEN vbtyp = 'C' THEN vbeln END)    AS n_pedidos         -- Cant. de pedidos (docs)
  FROM vbbe_open
  GROUP BY matnr, werks
),

-- (4) RESERVAS ABIERTAS — RESB (CDC -> estado vigente) -------------------------
--     Nota: RESB suele estar vacío en CDs de producto terminado (es de
--     componentes de producción); StockReser saldrá 0 en la mayoría de casos.
resb_open AS (
  SELECT CAST(matnr AS INT) AS matnr, TRIM(werks) AS werks, bdmng, enmng, kzear, xloek
  FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY rsnum, rspos, rsart
                              ORDER BY target_apply_ts DESC, header__change_seq DESC) AS rn
    FROM brewdat_uc_maz_prod.slv_maz_supply_sap_pr3.copecac_resb
    WHERE werks = 'SJ91'     -- ⚡ mismo prefiltro de centro (3 de 4)
  )
  WHERE rn = 1 AND op_ind IN ('I','U')
),
reserva AS (
  SELECT matnr, werks,
         SUM(CASE WHEN kzear <> 'X' AND (xloek IS NULL OR xloek <> 'X')
                  THEN (bdmng - enmng) ELSE 0 END) AS reserva_base
  FROM resb_open
  GROUP BY matnr, werks
)

-- (5) CASCADA FINAL (todo convertido a CAJAS + HL) ----------------------------
SELECT

  s.matnr                                                             AS Material,
  t.descripcion                                                       AS Descripcion,
  s.werks                                                             AS Centro,  
  c.tipo_material                                                     AS Tipo_Material,
  ROUND(s.clabs_base / c.umrez, 0)                                    AS Stock_Disp,
  ROUND(COALESCE(rq.entregas_base,0) / c.umrez, 0)                    AS Cant_Entrega_Pend,
  ROUND((s.clabs_base - COALESCE(rq.entregas_base,0)) / c.umrez, 0)   AS Total_Disponible,
  COALESCE(rq.n_pedidos, 0)                                           AS Cant_Pedidos,
  ROUND(COALESCE(rq.pedidos_base,0) / c.umrez, 0)                     AS Cantidad_En_Pedidos,
  ROUND((s.clabs_base - COALESCE(rq.entregas_base,0)
                      - COALESCE(rq.pedidos_base,0)) / c.umrez, 0)     AS Disponible_Final,
  ROUND(COALESCE(rs.reserva_base,0) / c.umrez, 0)                     AS StockReser,
  ROUND((s.clabs_base - COALESCE(rq.entregas_base,0)
                      - COALESCE(rq.pedidos_base,0)
                      - COALESCE(rs.reserva_base,0)) / c.umrez, 0)     AS CalDisFinal
  --ROUND((s.clabs_base / c.umrez) * ((c.umrez * c.volum) / 100000), 0) AS HL_Libre
FROM stock s
JOIN conv    c  ON c.matnr = s.matnr
LEFT JOIN txt     t  ON t.matnr = s.matnr
LEFT JOIN req     rq ON rq.matnr = s.matnr AND rq.werks = s.werks
LEFT JOIN reserva rs ON rs.matnr = s.matnr AND rs.werks = s.werks
WHERE c.mtart = 'FERT'          -- producto terminado (cerveza/bebidas). Quitar para todo material.
AND s.werks = 'SJ91'          -- <<< PARÁMETRO: centro. Nacional = LIKE 'BK%'/'SJ%'/'AH%'
ORDER BY Stock_Disp DESC;