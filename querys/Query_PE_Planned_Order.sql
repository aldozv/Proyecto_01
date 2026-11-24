-- Plan de entrega (ALZ 4.0), con los nombres de campo originales de pe_planned_order.
-- Reemplaza a revenue_h_pv_planeada. Filtro: entregas planeadas para hoy (hora Lima).
select
    distribution_center_name,
    order_type_code,
    customer_short_code,
    channel_subchannel_local_code,
    order_creation_date,
    planned_delivery_date,
    management_group,
    planned_volume_hl,
    product_category,
    order_number,
    sales_office_regional,
    order_line_number,
    sales_regional_name,
    product_short_code,
    customer_type,
    sales_zone_code
from brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order
where planned_delivery_date = to_date(from_utc_timestamp(current_timestamp(), 'America/Lima'))
limit 1000
