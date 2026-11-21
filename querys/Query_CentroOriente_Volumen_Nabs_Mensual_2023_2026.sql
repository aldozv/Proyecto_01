-- Volumen (HL) Nabs (Gaseosas + Agua sin San Mateo + Maltas) mensual Ene'23-Oct'26, Direccion Centro Oriente (jerarquia vigente). Marca desde dm_material (dm_venta.marca nula antes de 2024).
SELECT v.mes, SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
LEFT JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202301' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND v.estratificacion IN ('Gaseosas','Agua','Maltas')
  AND NOT (v.estratificacion = 'Agua' AND COALESCE(m.marca,'') = 'San Mateo')
GROUP BY v.mes ORDER BY 1
