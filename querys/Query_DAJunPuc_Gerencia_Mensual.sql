-- Total HL mensual SIN restriccion de CD (headline), gerencia PE Ger P4 DA Jun Puc.
-- EXCEPCION cliente_id 13836158 (Ucayali Beer S.A.C., CD Satipo): confirmado 2026-09-03 que
-- dm_venta.gerencia para este cliente vale 'PE Ger P4 Huancay Ch' hasta 202603 y recien pasa a
-- 'PE Ger P4 DA Jun Puc' desde 202604 (reclasificacion real del cliente, no ruido) -- vs
-- dm_cliente.gerencia (ficha vigente) que YA dice DA Jun Puc para todo el historico. A pedido
-- del usuario se reasigna el 100% del historico de este cliente a DA Jun Puc (ver
-- reglas_negocio.md). El resto de la gerencia sigue usando v.gerencia tal cual (regla general
-- de CLAUDE.md: v.gerencia, no c.gerencia, para no traer clientes reasignados a otras
-- direcciones -- Tacna/Piura/Chiclayo/Puno -- que si son ruido marginal, <175 HL en total).
SELECT
  CASE WHEN v.cliente_id = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.gerencia END AS gerencia,
  CAST(SUBSTR(v.mes,1,4) AS INT) AS anio,
  CAST(SUBSTR(v.mes,5,2) AS INT) AS mes_num,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
WHERE v.mes BETWEEN '202501' AND '202609'
  AND (v.gerencia = 'PE Ger P4 DA Jun Puc' OR v.cliente_id = '13836158')
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')
GROUP BY
  CASE WHEN v.cliente_id = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.gerencia END,
  CAST(SUBSTR(v.mes,1,4) AS INT), CAST(SUBSTR(v.mes,5,2) AS INT)
ORDER BY gerencia, anio, mes_num
