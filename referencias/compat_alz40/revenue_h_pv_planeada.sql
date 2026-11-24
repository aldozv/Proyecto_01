(
        -- Plan de entrega (PLAN), modelo ALZ 4.0 (desde 2026-11-24). Reemplaza revenue_h_pv_planeada;
        -- alias a los nombres antiguos para no cambiar el resto del query.
        select distribution_center_name as Centro, order_type_code as ClaseDocumento,
               customer_short_code as CodCliente, channel_subchannel_local_code as CodigoCanalSubcanalLocal,
               order_creation_date as FechaCreacionPedido, planned_delivery_date as FechaPlan,
               management_group as GrupoGerencia, planned_volume_hl as HLPlaneado, product_category as Linea,
               order_number as NumeroPedido, sales_office_regional as OficinaVentasRegional,
               order_line_number as PosicionPedido, sales_regional_name as Regional, product_short_code as SKU,
               customer_type as Tipo, sales_zone_code as ZonaPV
        from brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order
    )
