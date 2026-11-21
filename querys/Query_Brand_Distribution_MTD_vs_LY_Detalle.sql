-- Brand Distribution MTD (fecha_venta 1-18 Oct) 2026 vs 2025, Beer+Rtds, Centro Oriente.
-- El flag cae en la fecha de primera compra del mes del cliente-material, por eso filtrar fecha_venta da el BD MTD.
-- Grano: gerencia (de la tabla BD; SELLOUT no cruza dm_cliente) x CD (solo SELLIN) x brand_pack x anio.
-- Regla oficial (aplicar post-query): Pucall Hco/Huancay Ch -> SELLIN; Iquitos/Tarapoto -> SELLIN+SELLOUT; DA Jun Puc -> SELLOUT.
select
    v.gerencia,
    coalesce(c.centro_id, 'SIN_CD') as centro_id,
    m.brand_pack,
    m.estratificacion,
    year(v.fecha_venta) as anio,
    sum(case when v.tipo ilike '%SELLIN%' then v.flag_brand_distro else 0 end) as sellin,
    sum(case when v.tipo ilike '%SELLOUT%' then v.flag_brand_distro else 0 end) as sellout
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.mes in ('202510','202610')
and (v.fecha_venta between '2025-10-01' and '2025-10-18' or v.fecha_venta between '2026-10-01' and '2026-10-18')
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and m.brand_pack not in ('N.A', 'Corona Tropical 355 CAN', 'P.Trujillo 620 RB', 'P.Trujillo 473 CAN',
                          'P.Trujillo 355 CAN', 'Arequipeña 620 RB', 'Arequipeña 473 CAN',
                          'Kauffmann 355 CAN', 'Pacífico Clara 355 CAN', 'Barbarian 269 CAN')
group by 1,2,3,4,5
