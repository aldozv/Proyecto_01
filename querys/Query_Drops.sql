--Este query te brinda el resultado de drop (ya te explique que era drop) segun cliente y brandpack

SELECT * FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_revenue.revenue_dev_vw_rev_maestro_drops_brandpack
WHERE direccion = 'PE Dir Centro Orient'
--AND unidad_negocio in ('Off Premise','On Premise')
 