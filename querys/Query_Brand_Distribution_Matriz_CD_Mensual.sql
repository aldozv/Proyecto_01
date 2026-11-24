-- Brand Distribution: matriz CD x mes, ene'24 a set'26, Direccion Centro Oriente
-- Alcance: Cervezas + Licores + Ready To Drink. Total oficial por gerencia (regla aplicada por
-- transaccion segun su gerencia real, luego agrupado por CD del cliente via dm_cliente):
--   Pucall Hco y Huancay Ch -> solo SELLIN
--   Iquitos y Tarapoto      -> SELLIN + SELLOUT
--   DA Jun Puc              -> solo SELLOUT
-- CDs: lista confirmada de Centro Oriente (13, ver CLAUDE.md) via dm_cliente.centro_id.
-- OJO: un CD puede recibir clientes de mas de una gerencia -- este corte NO tiene por que coincidir
-- exacto con el corte por gerencia (Query_Brand_Distribution_Matriz_Gerencia_Mensual.sql), son
-- particiones distintas de los mismos clientes.
-- Fuente de datos del artifact "Evolución de Brand Distribution" -- reejecutar y volver a pegar
-- los arrays si se necesita refrescar.
select
    c.distribution_center_code as centro_id,
    v.mes,
    sum(case
        when v.gerencia in ('PE Ger P4 Pucall Hco', 'PE Ger P4 Huancay Ch') and v.tipo ilike '%SELLIN%' then v.flag_brand_distro
        when v.gerencia in ('PE Ger P4 Iquitos', 'PE Ger P4 Tarapoto') then v.flag_brand_distro
        when v.gerencia = 'PE Ger P4 DA Jun Puc' and v.tipo ilike '%SELLOUT%' then v.flag_brand_distro
        else 0
    end) as brand_distribution_oficial
from brewdat_uc_delta_maz_mazana_dev.slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution v
left join brewdat_uc_maz_dev.gld_maz_sales_portfolio_pe.pe_portfolio_material m on v.material_id = m.material_id
left join brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer c on c.customer_short_code = v.cliente_id
where v.direccion ilike '%PE Dir Centro Orient%'
and v.fecha_venta between '2024-01-01' and '2026-09-30'
and m.estratificacion in ('Cervezas', 'Licores', 'Ready To Drink')
and c.distribution_center_code in ('BK31','BK43','BK68','SJ01','SJ86','SJ87','SJ90','SJ91','SJ92','SJ93','SJ94','SJ95','SJ97')
group by c.distribution_center_code, v.mes
order by c.distribution_center_code, v.mes
