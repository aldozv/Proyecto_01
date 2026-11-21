-- Volumen (HL) mensual Ene'24-Oct'26 de categorias de expansion, Direccion Centro Oriente (jerarquia vigente).
-- Nolo = Corona Cero + Cusqueña Cero Trigo (definido por el usuario 13.11.26). Marca desde dm_material.  Pilsen Fresh = marcas 'Pilsen Fresh' + 'Pilsen Callao Fresh' (SKUs nuevos desde Ago'26).
SELECT v.mes,
  CASE WHEN m.marca IN ('Pilsen Fresh','Pilsen Callao Fresh') THEN 'Pilsen Fresh'
       WHEN m.marca IN ('Corona Cero','Cusqueña Cero Trigo') THEN 'Nolo'
       WHEN m.marca = 'Flying Fish' THEN 'Flying Fish' END AS grupo,
  SUM(v.hl) AS hl
FROM brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_venta v
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_cliente c ON v.cliente_id = c.cliente_id
INNER JOIN brewdat_uc_mazana_dev.slv_maz_dataexperience_peru_dm.dm_material m ON v.material_id = m.material_id
WHERE v.mes BETWEEN '202401' AND '202610'
  AND c.direccion = 'PE Dir Centro Orient'
  AND v.indicadores_comerciales = 1
  AND m.marca IN ('Pilsen Fresh','Pilsen Callao Fresh','Corona Cero','Cusqueña Cero Trigo','Flying Fish')
GROUP BY 1, 2 ORDER BY 2, 1
