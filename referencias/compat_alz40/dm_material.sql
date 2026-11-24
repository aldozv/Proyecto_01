(
        -- dm_material sobre ALZ 4.0 (pe_product), alias a nombres antiguos. Ver BITACORA_TABLAS.md
        select
           s.product_line as estratificacion,
           s.product_status as estado,
           s.brand_family_name as familia,
           s.product_update_at as fecha_actualizacion,
           s.brand_name as marca,
           s.marketplace_flag as marketplace_flag,
           s.product_short_code as material_id,
           s.product_name as nombre,
           s.product_type_name as nombre_tipo,
           s.pack as pack,
           s.country_code as pais_id,
           s.base_uom_gross_weight as peso_bruto,
           s.base_uom_net_weight as peso_neto,
           s.presentation_name as presentacion,
           s.product_type_code as tipo,
           s.container_returnable_name as tipo_envase,
           s.container_capacity_name as tipoenvasejerarquia,
           s.base_uom_code as unidad_medida_base,
           s.base_uom_weight_unit as unidad_medida_peso,
           s.base_uom_quantity as unidades_caja,
           s.base_uom_volume as volumen
        from brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product s
    )