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
  CASE WHEN v.sold_to_customer_short_code = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.sales_region_name END AS gerencia,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT) AS anio,
  CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT) AS mes_num,
  SUM(v.sales_volume_official) AS hl
FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
    left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product v_p on v_p.product_short_code = v.product_short_code
WHERE cast(v.__partition_column as string) BETWEEN '202501' AND '202609'
  AND (v.sales_region_name = 'PE Ger P4 DA Jun Puc' OR v.sold_to_customer_short_code = '13836158')
  AND v.invoice_commercial_flag = 1
  AND v_p.product_line IN ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  AND NOT (v_p.product_line = 'Agua' AND v_p.brand_name = 'San Mateo')
GROUP BY
  CASE WHEN v.sold_to_customer_short_code = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.sales_region_name END,
  CAST(SUBSTR(cast(v.__partition_column as string),1,4) AS INT), CAST(SUBSTR(cast(v.__partition_column as string),5,2) AS INT)
ORDER BY gerencia, anio, mes_num
