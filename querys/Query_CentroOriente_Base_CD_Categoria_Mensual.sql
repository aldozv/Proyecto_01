-- Base CD x Categoria x Canal mensual, por gerencia. Alimenta Total, Categoria, CD y el filtro
-- global de Canal del dashboard (canal_meta = unidad_negocio_revenue_volumen_meta).
-- CD acotado a la lista curada confirmada por gerencia (ver reglas_negocio.md / SKILL.md):
--   Pucallpa: CD Pucallpa, CD Huánuco, CD Tingo María, CD Iquitos, CD Yurimaguas, CD Tarapoto
--             (los ultimos 3 son un cliente real -- Naviera Oriente S.A.C. -- con codigo
--             distinto por plaza fluvial, canal DSD OFF; confirmado 2026-08-31)
--   Tarapoto: CD Tarapoto, CD Yurimaguas, CD Moyobamba, CD Pucallpa, CD San Benedicto I (Ate),
--             CD Motupe, CD Chiclayo (Pucallpa confirmado 2026-08-27; San Benedicto I (Ate) y
--             Motupe, 100% canal DAs, confirmados 2026-08-29; Chiclayo, 1 cliente Key Accounts
--             -- Plaza Vea Oriente S.A.C. --, confirmado 2026-08-31)
--   Iquitos:  CD Iquitos, CD Pucallpa (100% canal DAs, confirmado 2026-08-29)
--   Huancay Ch: CD Huancayo, CD Chanchamayo, CD Satipo, CD Huancavelica
SELECT
  v.gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END AS categoria_grupo,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar') AS canal_meta,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
  ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202401' AND '202609'
  AND v.gerencia IN ('PE Ger P4 Tarapoto','PE Ger P4 Iquitos','PE Ger P4 Pucall Hco','PE Ger P4 Huancay Ch','PE Ger P4 DA Jun Puc')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
  AND c.centro IN ('CD Pucallpa','CD Huánuco','CD Tingo María','CD Tarapoto','CD Yurimaguas','CD Moyobamba','CD Iquitos','CD Huancayo','CD Chanchamayo','CD Satipo','CD Huancavelica','CD San Benedicto I (Ate)','CD Motupe','CD Chiclayo')
GROUP BY
  v.gerencia, CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT), c.centro,
  CASE
    WHEN v.estratificacion IN ('Cervezas','Licores') THEN 'Beer'
    WHEN v.estratificacion = 'Ready To Drink' THEN 'Rtds'
    WHEN v.estratificacion IN ('Gaseosas','Agua','Maltas') THEN 'Nabs'
  END,
  COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar')
ORDER BY v.gerencia, anio, mes_num, centro, categoria_grupo, canal_meta
