-- Tracking diario GV Pucallpa, modelo ALZ 4.0 con nombres de campo nativos (sin alias antiguos).
-- FACT: pe_invoice | PLAN: pe_planned_order | PV D+1: pe_flash_order | PV FUT: pe_order
-- cliente: pe_customer | material: pe_product. Solo revenue_maestro_sku sigue en el modelo anterior.
-- pe_flash_order guarda una foto por hora acumulada: se usa solo la ultima foto tipo FE (por fecha de entrega).
-- pe_order corta ~05:05 Lima: lo creado despues aparece en PV FUT recien al dia siguiente.
-- Columnas de salida iguales a Query_Pucallpa_Tracking_Diario.sql.

/*VENTA FACTURADA MTD*/
(
SELECT
b.customer_short_code as codigo,
b.customer_name as nombre,
b.sales_region_name as gerencia,
b.distribution_center_name as centro,
CASE
WHEN b.business_unit_target_volume in ('DSD OFF') then 'DSD OFF'
WHEN b.business_unit_target_volume in ('DSD ON','High End') then 'DSD ON'
WHEN b.business_unit_target_volume in ('Mayoristas') then 'WHL'
WHEN b.business_unit_target_volume in ('Eventos') then 'EVE'
WHEN b.business_unit_target_volume in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.business_unit_target_volume in ('DAs') then 'DAS'
WHEN b.business_unit_target_volume is null then 'DSD OFF'
ELSE b.business_unit_target_volume
END AS canal_grupo,
b.business_unit_one_year_plan as unidad_negocio_1yp,
b.business_unit_target_volume as unidad_negocio_meta,
b.sales_subregion_name as supervisor,
b.sales_zone_comission_code as zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.product_name as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.order_date as fecha_preventa,
a.invoice_date as fecha_entrega,
sum(a.sales_volume_official) as HL,
sum(a.sales_volume_official)*13.4408602150538 as CE,
--Caja fisica por SKU: HL x 100000 / (ml por unidad x unidades por caja). Misma formula en los 4 tipos
CAST(ROUND(SUM(a.sales_volume_official*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
DATEADD(hour, -5, CURRENT_TIMESTAMP()) as hora_corte,
'FACT' as TIPO,
a.invoice_number as numero_venta

FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice a
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.sold_to_customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code

WHERE b.sales_area_name in ('PE Dir Centro Orient')
AND b.sales_region_name IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
--Mes en curso, a hora de Lima
AND cast(a.__partition_column as string) = DATE_FORMAT(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), "yyyyMM")
AND a.invoice_commercial_flag = 1
--Hasta ayer: lo de hoy esta en PLAN
AND a.invoice_date < CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
GROUP BY ALL
)
UNION ALL

/*PLAN ENTREGA DE HOY*/
(
SELECT
b.customer_short_code as codigo,
b.customer_name as nombre,
b.sales_region_name as gerencia,
b.distribution_center_name as centro,
CASE
WHEN b.business_unit_target_volume in ('DSD OFF') then 'DSD OFF'
WHEN b.business_unit_target_volume in ('DSD ON','High End') then 'DSD ON'
WHEN b.business_unit_target_volume in ('Mayoristas') then 'WHL'
WHEN b.business_unit_target_volume in ('Eventos') then 'EVE'
WHEN b.business_unit_target_volume in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.business_unit_target_volume in ('DAs') then 'DAS'
WHEN b.business_unit_target_volume is null then 'DSD OFF'
ELSE b.business_unit_target_volume
END AS canal_grupo,
b.business_unit_one_year_plan as unidad_negocio_1yp,
b.business_unit_target_volume as unidad_negocio_meta,
b.sales_subregion_name as supervisor,
b.sales_zone_comission_code as zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.product_name as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.order_creation_date as fecha_creacion,
a.planned_delivery_date as fecha_entrega,
sum(a.planned_volume_hl) as HL,
sum(a.planned_volume_hl)*13.4408602150538 as CE,
CAST(ROUND(SUM(a.planned_volume_hl*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
DATEADD(hour, -5, CURRENT_TIMESTAMP()) as hora_corte,
'PLAN' as TIPO,
a.order_number as NumeroPedido

FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order a
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code

WHERE b.sales_area_name in ('PE Dir Centro Orient')
AND b.sales_region_name IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
AND a.planned_delivery_date = CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
AND b.customer_short_code > 10000000
GROUP BY ALL
)
UNION ALL

/*PREVENTA D+1*/
(
SELECT
b.customer_short_code as codigo,
b.customer_name as nombre,
b.sales_region_name as gerencia,
b.distribution_center_name as centro,
CASE
WHEN b.business_unit_target_volume in ('DSD OFF') then 'DSD OFF'
WHEN b.business_unit_target_volume in ('DSD ON','High End') then 'DSD ON'
WHEN b.business_unit_target_volume in ('Mayoristas') then 'WHL'
WHEN b.business_unit_target_volume in ('Eventos') then 'EVE'
WHEN b.business_unit_target_volume in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.business_unit_target_volume in ('DAs') then 'DAS'
WHEN b.business_unit_target_volume is null then 'DSD OFF'
ELSE b.business_unit_target_volume
END AS canal_grupo,
b.business_unit_one_year_plan as unidad_negocio_1yp,
b.business_unit_target_volume as unidad_negocio_meta,
b.sales_subregion_name as supervisor,
b.sales_zone_comission_code as zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.product_name as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.order_creation_date as fecha_creacion,
a.requested_delivery_date as fecha_entrega,
sum(a.order_requested_quantity_hl) as HL,
sum(a.order_requested_quantity_hl)*13.4408602150538 as CE,
CAST(ROUND(SUM(a.order_requested_quantity_hl*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
DATEADD(hour, -5, CURRENT_TIMESTAMP()) as hora_corte,
'PV D+1' as TIPO,
a.order_number as pedido

FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order a
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code

WHERE b.sales_area_name in ('PE Dir Centro Orient')
AND b.sales_region_name IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
AND b.customer_short_code > 10000000
AND a.cancelled_flag = false
--Ultima foto horaria tipo FE (por fecha de entrega). Sumar varias fotos multiplica el volumen
AND a.order_flash_type = 'FE'
AND a.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1)
AND a.snapshot_timestamp = (SELECT MAX(s.snapshot_timestamp) FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order s WHERE s.order_flash_type = 'FE' AND s.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1))
--Solo la siguiente fecha de reparto de la GV (el sabado es el lunes). Las posteriores van en PV FUT
AND a.requested_delivery_date = (SELECT MIN(f.requested_delivery_date) FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order f JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer g ON g.customer_short_code = f.customer_short_code WHERE g.sales_region_name = 'PE Ger P4 Pucall Hco' AND f.order_flash_type = 'FE' AND f.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1) AND f.snapshot_timestamp = (SELECT MAX(s.snapshot_timestamp) FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order s WHERE s.order_flash_type = 'FE' AND s.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1)) AND f.requested_delivery_date > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE))
GROUP BY ALL
)
UNION ALL

/*PREVENTA FUTURA (SIN PLAN DE HOY NI PREVENTA DE HOY) */
(
SELECT
b.customer_short_code as codigo,
b.customer_name as nombre,
b.sales_region_name as gerencia,
b.distribution_center_name as centro,
CASE
WHEN b.business_unit_target_volume in ('DSD OFF') then 'DSD OFF'
WHEN b.business_unit_target_volume in ('DSD ON','High End') then 'DSD ON'
WHEN b.business_unit_target_volume in ('Mayoristas') then 'WHL'
WHEN b.business_unit_target_volume in ('Eventos') then 'EVE'
WHEN b.business_unit_target_volume in ('C&C','SMK','TCs','Key Accounts') then 'KA'
WHEN b.business_unit_target_volume in ('DAs') then 'DAS'
WHEN b.business_unit_target_volume is null then 'DSD OFF'
ELSE b.business_unit_target_volume
END AS canal_grupo,
b.business_unit_one_year_plan as unidad_negocio_1yp,
b.business_unit_target_volume as unidad_negocio_meta,
b.sales_subregion_name as supervisor,
b.sales_zone_comission_code as zona_comisional,

CASE
WHEN d.categoria in ('Cervezas','Licores') then 'BEER'
WHEN d.categoria in ('Ready to drink') then 'RTDS'
WHEN d.categoria in ('Gaseosas','Agua','Maltas') then 'NABS'
WHEN d.categoria is null then 'BEER'
ELSE d.categoria
END AS categoria_grupo,

d.categoria,
d.marca,
d.marca_gpa,
d.pack,
d.pack_xxx,
d.sku,
d.`Agrupador (Sku)`,
c.product_name as nombre_sku,
d.ms_ss,
d.kpi_premium as premium,
a.order_creation_date as fecha_creacion,
a.requested_delivery_date as fecha_entrega,
sum(a.order_requested_quantity_hl) as HL,
sum(a.order_requested_quantity_hl)*13.4408602150538 as CE,
CAST(ROUND(SUM(a.order_requested_quantity_hl*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
DATEADD(hour, -5, CURRENT_TIMESTAMP()) as hora_corte,
'PV FUT' as TIPO,
a.order_number as numero_preventa

FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_order a
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code

WHERE b.sales_area_name in ('PE Dir Centro Orient')
AND b.sales_region_name IN ('PE Ger P4 Pucall Hco')
AND d.categoria IN ('Cervezas', 'Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas', 'Licores','Ready to drink')
--Particion: mes anterior y en curso (cubre preventas creadas a fin del mes pasado)
AND a.period >= DATE_FORMAT(ADD_MONTHS(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), -1), "yyyyMM")
AND a.requested_delivery_date > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE)
--Hasta el ultimo dia del mes en curso, a hora de Lima
AND a.requested_delivery_date <= LAST_DAY(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE))
--Excluye solo la fecha que trae PV D+1. IS DISTINCT FROM evita que PV FUT quede vacio si esa fecha es nula
AND a.requested_delivery_date IS DISTINCT FROM (SELECT MIN(f.requested_delivery_date) FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order f JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer g ON g.customer_short_code = f.customer_short_code WHERE g.sales_region_name = 'PE Ger P4 Pucall Hco' AND f.order_flash_type = 'FE' AND f.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1) AND f.snapshot_timestamp = (SELECT MAX(s.snapshot_timestamp) FROM brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order s WHERE s.order_flash_type = 'FE' AND s.snapshot_date >= DATE_SUB(CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE), 1)) AND f.requested_delivery_date > CAST(DATEADD(hour, -5, CURRENT_TIMESTAMP()) AS DATE))
AND a.order_flow_type = 1
AND b.customer_short_code > 10000000
AND a.order_reject_name IS NULL
GROUP BY ALL
)
