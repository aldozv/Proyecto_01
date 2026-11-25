-- Volumen facturado diario Centro Oriente por cliente, zona comisional, supervisor, gerencia, direccion y SKU.
-- Modelo ALZ 4.0 con campos nativos. Fuente: pe_invoice (venta), pe_customer (jerarquia vigente del cliente),
-- pe_product (factor de caja fisica), revenue_maestro_sku (categoria/marca).
-- Jerarquia (direccion/gerencia/supervisor/zona) sale del maestro de cliente vigente, no de la venta (regla 2026-09-04).
-- Alcance: categorias Backus (deja fuera Marketplace y SKU sin categoria); San Mateo excluido.
-- Para dejar solo Beer+Rtds, activar el filtro comentado de categoria.
-- Rango de fechas: cambiar las dos fechas de invoice_date y los meses de __partition_column juntos.

SELECT
a.invoice_date as fecha,
b.sales_area_name as direccion,
b.sales_region_name as gerencia,
b.sales_subregion_name as supervisor,
b.sales_zone_comission_code as zona_comisional,
b.customer_short_code as codigo_cliente,
b.customer_name as nombre_cliente,
d.categoria,
d.marca,
a.product_short_code as sku,
c.product_name as nombre_sku,
--Caja fisica por SKU: HL x 100000 / (ml por unidad x unidades por caja)
CAST(ROUND(SUM(a.sales_volume_official*100000/NULLIF(c.base_uom_volume*c.base_uom_quantity,0)),0) AS BIGINT) as CF,
SUM(a.sales_volume_official) as HL

FROM brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice a
JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer b on b.customer_short_code = a.sold_to_customer_short_code
LEFT JOIN brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product c on c.product_short_code = a.product_short_code
LEFT JOIN brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d on d.sku = a.product_short_code

WHERE b.sales_area_name = 'PE Dir Centro Orient'
AND a.invoice_commercial_flag = 1
AND cast(a.__partition_column as string) IN ('202611')
AND a.invoice_date between '2026-11-01' and '2026-11-24'
AND d.categoria IN ('Cervezas','Licores','Ready to drink','Gaseosas','Agua','Maltas')
--AND d.categoria IN ('Cervezas','Licores','Ready to drink')
AND coalesce(d.marca,'') <> 'San Mateo'
GROUP BY ALL
LIMIT 1000000
