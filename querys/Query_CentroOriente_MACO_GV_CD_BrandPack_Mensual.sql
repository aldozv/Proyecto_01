-- Historico mensual de MACO por GV x CD x brand_pack (con marca, marca GPA y pack), Centro Oriente, Beer+Rtds.
-- Rango: Ene'24 - Oct'26 (meses cerrados; 2026 vs LY y vs 2024 — usuario pidio desde 2024).
-- MACO = NR + VIC + VLC (VIC/VLC en negativo), en soles. MACO/HL se calcula despues como
-- SUM(maco)/SUM(hl) sobre el corte que se quiera (no promediar ratios), por eso no va en el query.
-- Jerarquia vigente desde dm_cliente (regla 2026-09-04): gerencia, centro_id y direccion.
-- brand_pack desde pe_portfolio_material (mismo maestro que Brand Distribution);
-- marca, marca_gpa y pack desde revenue_maestro_sku (carga manual; mismo maestro que el tracking).
-- dm_venta.marca viene NULL antes de 2024, por eso no se usa.
select
    v.mes,
    c.gerencia,
    coalesce(c.centro_id, 'Sin CD')         as centro_id,
    v.estratificacion,
    coalesce(m.brand_pack, 'Sin brandpack') as brand_pack,
    coalesce(s.marca, 'Sin marca')          as marca,
    coalesce(s.marca_gpa, 'Sin marca GPA')  as marca_gpa,
    coalesce(s.pack, 'Sin pack')            as pack,
    sum(v.hl)                               as hl,
    cast(round(sum(v.caja_fisica)) as bigint) as caja_fisica,
    sum(v.nr)                               as nr,
    sum(v.vic)                              as vic,
    sum(v.vlc)                              as vlc,
    sum(v.maco)                             as maco
from brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c
    on v.cliente_id = c.cliente_id
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m
    on v.material_id = m.material_id
left join brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_maestro_sku s
    on v.material_id = s.sku
where v.mes between 202401 and 202610
  and v.indicadores_comerciales = 1
  and c.direccion = 'PE Dir Centro Orient'
  and v.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
group by v.mes, c.gerencia, coalesce(c.centro_id, 'Sin CD'), v.estratificacion,
         coalesce(m.brand_pack, 'Sin brandpack'), coalesce(s.marca, 'Sin marca'),
         coalesce(s.marca_gpa, 'Sin marca GPA'), coalesce(s.pack, 'Sin pack')
