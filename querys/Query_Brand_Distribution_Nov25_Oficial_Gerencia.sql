-- BD oficial Nov'25 mes completo por GV (base para proyectar cierre Nov'26 = LY x (1 + var MTD)).
-- SELLIN con gerencia vigente de dm_cliente; SELLOUT con gerencia de la tabla BD (no cruza dm_cliente).
-- Mismos filtros que Query_Brand_Distribution_Nov_MTD_vs_LY_Supervisor_BrandPack.sql. Regla oficial por GV post-query.
select b.tipo,
       case when b.tipo = 'SELLIN' then c.gerencia else b.gerencia end as gerencia,
       sum(case when day(b.fecha_venta) <= 16 then b.flag_brand_distro else 0 end) as bd_1_16,
       sum(case when day(b.fecha_venta) <= 14 then b.flag_brand_distro else 0 end) as bd_1_14,
       sum(b.flag_brand_distro) as bd_mes
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution b
join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = b.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c on c.cliente_id = b.cliente_id
where b.mes = '202511'
  and m.estratificacion in ('Cervezas','Licores','Ready To Drink')
  and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN','Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
  and ((b.tipo = 'SELLIN' and c.direccion = 'PE Dir Centro Orient') or (b.tipo = 'SELLOUT' and b.direccion = 'PE Dir Centro Orient'))
group by 1,2
