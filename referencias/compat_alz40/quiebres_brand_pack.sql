(
        -- Quiebres BEES, modelo ALZ 4.0 (desde 2026-11-24). Alias a los nombres de la tabla anterior
        -- (dev_onep_fact_critical_items_summary_24h_brand_pack_gold) para no cambiar el resto del query.
        select period as mes, out_of_stock_date, distribution_center_code as centro_id,
               brand_pack_name as brand_pack, active_flag as activo_en_cd,
               brand_pack_product_quantity as cant_skus_brand_pack, available_hours as horas_disponibles,
               out_of_stock_hours as horas_oos_brand_pack, in_stock_hours as horas_prendidas_brand_pack,
               out_of_stock_hours_percentage as pct_horas_oos_brand_pack, uptime_percentage as pct_uptime_brand_pack,
               lost_sales_volume_hl as hl_so_brand_pack, average_presale_volume_hl as hl_pv_promedio_bp,
               presale_day_flag as flag_preventa_dia, max_out_of_stock_days_quantity as max_length_of_time_days,
               out_of_stock_product_quantity as skus_en_quiebre, brand_pack_product_list as skus_brand_pack_list,
               out_of_stock_product_list as skus_oos_list
        from brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack
    )
