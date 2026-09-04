-- Brand Distribution: matriz Marca x Pack (brand_pack) x mes, ene'24 a ago'26, Direccion Centro Oriente
-- Alcance: Cervezas + Licores + Ready To Drink. Total oficial por gerencia (regla aplicada por
-- transaccion segun su gerencia real, luego agrupado por brand_pack del material):
--   Pucall Hco y Huancay Ch -> solo SELLIN
--   Iquitos y Tarapoto      -> SELLIN + SELLOUT
--   DA Jun Puc              -> solo SELLOUT
-- Excluir brand_pack = 'N.A' (placeholder/dato basura, 1 sola fila en toda la serie) y los
-- brand_pack que el usuario pidio sacar del grafico por bajisimo volumen/no relevantes
-- (2026-09-01): Corona Tropical, P.Trujillo (todos), Arequipeña (todos), Kauffmann, Pacífico
-- Clara, Barbarian.
-- Fuente de datos del artifact "Evolución de Brand Distribution" -- reejecutar y volver a pegar
-- los arrays si se necesita refrescar.
select
    m.brand_pack,
    v.mes,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as brand_distribution_oficial
from brewdat_uc_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_scus_weu_sales_dev_ds.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-08-31'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and m.brand_pack not in ('N.A', 'Corona Tropical 355 CAN', 'P.Trujillo 620 RB', 'P.Trujillo 473 CAN',
                          'P.Trujillo 355 CAN', 'Arequipeña 620 RB', 'Arequipeña 473 CAN',
                          'Kauffmann 355 CAN', 'Pacífico Clara 355 CAN', 'Barbarian 269 CAN')
group by m.brand_pack, v.mes
order by m.brand_pack, v.mes
