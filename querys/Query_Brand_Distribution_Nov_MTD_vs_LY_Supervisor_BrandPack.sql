-- Brand Distribution MTD Nov (dia 1 a dia -1) 2026 vs 2025, Beer+Rtds, Centro Oriente.
-- Recalculado desde la venta porque pe_portfolio_hm_brand_distribution dejo de cargar el 22.10.26.
-- Logica: 1 punto de BD por cliente-material con compra neta (caja_fisica) > 0 en la ventana.
-- Validado en Nov 1-16 2025: SELLIN +1% a +1.8% sobre la oficial (sesgo parejo por GV),
-- SELLOUT exacto (Tarapoto 17,727; Iquitos 1,420; DA Jun Puc 21,047 vs 21,045).
-- Ventana: SELLIN 1-16 Nov; SELLOUT 1-14 Nov (dm_das_venta llega al 14.11 al 17.11.26). Mismos dias LY.
-- SELLIN: dm_venta + dm_cliente (gerencia/supervisor vigentes). SELLOUT: dm_das_venta + dm_das_cliente
-- (nivel2 = distribuidor, no hay supervisor). Regla oficial por GV (aplicar post-query):
-- Pucall Hco/Huancay Ch -> SELLIN; Iquitos/Tarapoto -> SELLIN+SELLOUT; DA Jun Puc -> SELLOUT.
with sellin as (
  select v.sold_to_customer_short_code as cliente_id, v.product_short_code as material_id, year(v.invoice_date) as anio
  from brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice v
  where cast(v.__partition_column as string) in ('202511','202611')
    and (v.invoice_date between '2025-11-01' and '2025-11-16' or v.invoice_date between '2026-11-01' and '2026-11-16')
    and v.invoice_commercial_flag = 1
  group by 1,2,3 having sum(v.billed_sales_boxes_quantity) > 0
),
dc as (
  select cliente_id, gerencia, sociedad
  from brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_cliente
  where direccion = 'PE Dir Centro Orient'
),
sellout as (
  select v.cliente_id, v.material_id, year(v.fecha_venta) as anio
  from brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_das_venta v
  join dc on dc.cliente_id = v.cliente_id
  where v.mes in ('202511','202611')
    and (v.fecha_venta between '2025-11-01' and '2025-11-14' or v.fecha_venta between '2026-11-01' and '2026-11-14')
  group by 1,2,3 having sum(v.caja_fisica) > 0
),
base as (
  select 'SELLIN' as tipo, c.sales_region_name as gerencia, coalesce(c.sales_subregion_name, 'SIN SUPERVISOR') as nivel2, s.cliente_id, s.material_id, s.anio
  from sellin s
  join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = s.cliente_id
  where c.sales_area_name = 'PE Dir Centro Orient'
  union all
  select 'SELLOUT' as tipo, dc.gerencia, dc.sociedad as nivel2, o.cliente_id, o.material_id, o.anio
  from sellout o
  join dc on dc.cliente_id = o.cliente_id
)
select b.tipo, b.gerencia, b.nivel2, m.brand, m.brand_pack, b.anio,
       count(*) as bd,
       count(distinct b.cliente_id) as pocs
from base b
join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = b.material_id
where m.estratificacion in ('Cervezas','Licores','Ready To Drink')
  and m.brand_pack not in ('N.A','Corona Tropical 355 CAN','P.Trujillo 620 RB','P.Trujillo 473 CAN','P.Trujillo 355 CAN',
                           'Arequipeña 620 RB','Arequipeña 473 CAN','Kauffmann 355 CAN','Pacífico Clara 355 CAN','Barbarian 269 CAN')
group by 1,2,3,4,5,6
