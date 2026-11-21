-- Volumen Beer+Rtds mensual 2021-2022, Direccion Centro Oriente (jerarquia vigente dm_cliente). Para v6 (anual desde 2021).
SELECT v.mes, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
WHERE v.mes BETWEEN '202101' AND '202212'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Cervezas','Licores','Ready To Drink')
GROUP BY v.mes ORDER BY 1
