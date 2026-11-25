-- Volumen facturado Centro Oriente (Beer+Rtds) por cliente, gerencia, CD, canal, supervisor, zona comisional,
-- SKU y fecha de entrega. Modelo ALZ 4.0 con campos nativos. Query del usuario, corregido 2026-11-25:
--  1. Categorias desde pe_product_additional_details de PROD (la copia de dev no tiene SKUs nuevos:
--     Cusqueña Chocolate, Pilsen Callao Fresh, Corona Cero -> ~720 HL menos en Nov'26).
--  2. HL = sales_volume_official (no sales_volume).
--  3. Filtro comercial: invoice_commercial_flag = 1.
--  4. CF calculada por SKU: HL x 100000 / (ml por unidad x unidades por caja)
--     (billed_sales_boxes_quantity no es confiable: decimales y ratios CF/HL fuera de rango).

SELECT
b.customer_short_code as codigo,
b.customer_name,
b.sales_region_name,
b.distribution_center_name,
CASE
WHEN b.business_unit_one_year_plan in ('DSD OFF','DSD ON','High End') then 'DSD'
WHEN b.business_unit_one_year_plan in ('Mayoristas','Eventos') then 'WHL'
WHEN b.business_unit_one_year_plan in ('C&C','SMK','TCs') then 'KA'
WHEN b.business_unit_one_year_plan in ('DAs') then 'DAS'
WHEN b.business_unit_one_year_plan is null then 'DSD'
ELSE b.business_unit_one_year_plan
END AS canal_grupo,
b.business_unit_one_year_plan as unidad_negocio,
b.sales_subregion_name,
b.sales_zone_comission_code,
d.product_category,
d.brand_name,
d.pack,
d.product_group,
d.product_short_code,
c.product_name as nombre_sku,
d.kpi_premium as premium,
d.ms_ss_indicator as multipack,
--a.order_creation_date as fecha_preventa,
a.invoice_date as fecha_entrega,
sum(a.sales_volume_official) as HL,
CAST(ROUND(SUM(a.sales_volume_official*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
'FACT' as TIPO

FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice a
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.sold_to_customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_maz_prod.slv_maz_masterdata_manual.pe_product_additional_details d on d.product_short_code = a.product_short_code

WHERE b.sales_area_name in ('PE Dir Centro Orient')
AND d.product_category IN ('Cervezas', 'Licores','Ready to drink')
--AND d.product_category IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
AND a.__partition_column IN (202611)
AND a.invoice_commercial_flag = 1
GROUP BY ALL
