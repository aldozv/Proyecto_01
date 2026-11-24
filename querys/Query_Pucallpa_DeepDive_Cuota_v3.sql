-- Deep dive GV Pucallpa (23.11.26): cuota de volumen (dm_volumen_meta) al mismo grano del detalle v3, para sumarla al dashboard.
--   CUOTAYTD26 = cuota Ene-Oct 2026 | CUOTA2611 = cuota de Nov 2026 (mes completo).
-- Mismos mapeos que Query_Pucallpa_DeepDive_Detalle_v3_Categoria_SKU.sql: GV/CD/supervisor/canal de dm_cliente (vigente), sin SJ01,
-- categoria Beer/Rtds/Nabs (Nabs sin San Mateo) via dm_material.estratificacion, producto via pe_portfolio_material / revenue_maestro_sku.
-- Columnas iguales al detalle (hl = cuota en HL, bd = 0) para anexarla al mismo archivo.
with q as (
  select case when q.mes between '202601' and '202610' then 'CUOTAYTD26' else 'CUOTA2611' end as periodo,
    q.cliente_id, q.material_id, q.hl
  from brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_dm.dm_volumen_meta q
  where q.mes between '202601' and '202611'
)
select q.periodo,
  case c.distribution_center_code when 'SJ97' then 'Pucallpa' when 'SJ90' then 'Huánuco' when 'SJ93' then 'Tingo María' else 'Otros CD' end as cd,
  case when c.sales_subregion_name like 'Promotor generico%' then 'Promotores genéricos'
       when upper(c.sales_subregion_name) like 'SUPERVISION KA%' then 'Supervisión KA'
       when c.sales_subregion_name = 'Trujillo Rubin, Cesar Jose' then 'Jose Trujillo'
       when c.sales_subregion_name is null then 'Sin supervisor'
       else initcap(c.sales_subregion_name) end as supervisor,
  coalesce(c.business_unit_target_volume, 'Sin clasificar') as canal,
  case when dm.product_line in ('Cervezas','Licores') then 'Beer' when dm.product_line = 'Ready To Drink' then 'Rtds' else 'Nabs' end as categoria,
  coalesce(m.brand_pack, 'Sin brandpack') as brand_pack,
  coalesce(s.marca, 'Sin marca') as marca,
  coalesce(s.marca_gpa, 'Sin marca GPA') as marca_gpa,
  coalesce(s.pack, 'Sin pack') as pack,
  coalesce(s.`Agrupador (Sku)`, 'Sin agrupador') as agrupador,
  concat(regexp_replace(cast(q.material_id as string), '^0+', ''), ' - ', coalesce(dm.product_name, 'Sin nombre')) as sku,
  round(sum(q.hl), 3) as hl, 0 as bd
from q
join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = q.cliente_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product dm on dm.product_short_code = q.material_id
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on m.material_id = q.material_id
left join brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s on s.sku = q.material_id
where c.sales_region_name = 'PE Ger P4 Pucall Hco' and c.distribution_center_code <> 'SJ01'
  and dm.product_line in ('Cervezas','Licores','Ready To Drink','Gaseosas','Agua','Maltas')
  and not (dm.product_line = 'Agua' and coalesce(s.marca, '') = 'San Mateo')
group by 1,2,3,4,5,6,7,8,9,10,11
having abs(sum(q.hl)) >= 0.0005
order by 1,2,3,4,5,6
limit 100000
