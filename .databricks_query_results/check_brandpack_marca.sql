SELECT
  `Agrupador (Sku)` AS brandpack,
  marca,
  COUNT(*) AS n_skus
FROM slv_maz_dataexperience_peru_revenue.revenue_maestro_sku
WHERE `Agrupador (Sku)` IN (
  'Budweiser CAN 355 x6','Budweiser RB 600','Corona Cero NRB 355','Corona Extra CAN 355',
  'Corona Extra CAN 473','Corona NRB 210','Corona NRB 330','Cristal 24x1 RB 305',
  'Cristal CAN 355 x12','Cristal CAN 355 x6','Cristal CAN 473','Cristal RB 1000','Cristal RB 650',
  'Cusqueña CAN 355','Cusqueña CAN 473','Cusqueña Doble Malta NRB 310','Cusqueña Malta 24x1 RB 310',
  'Cusqueña Malta CAN 355','Cusqueña Malta CAN 473','Cusqueña Malta NRB 310','Cusqueña Malta RB 620',
  'Cusqueña NRB 310','Cusqueña Quinua CAN 473','Cusqueña RB 620','Cusqueña Roja 310 NRB',
  'Cusqueña Roja 473 CAN','Cusqueña Trigo 24x1 RB 310','Cusqueña Trigo CAN 355','Cusqueña Trigo CAN 473',
  'Cusqueña Trigo CAN 473 Verano','Cusqueña Trigo Cero CAN 355','Cusqueña Trigo Cero NRB 310',
  'Cusqueña Trigo NRB 310','Cusqueña Trigo RB 620','Flying Fish CAN 355','Golden 473 CAN 4 + 2',
  'Golden CAN 269','Golden CAN 355','Golden CAN 473','Golden RB 620','Golden RB 650',
  'P. Callao 355 Verano','P. Callao 473 Verano','P.Callao CAN 269','P.Callao CAN 355 x12',
  'P.Callao CAN 355 x6','P.Callao CAN 473','P.Callao NRB 305','P.Callao RB 630','P.Fresh CAN 355',
  'P.Fresh CAN 473','P.Fresh NRB 305','P.Fresh RB 305','Pilsen Callao 24x1 RB 305',
  'Pilsen Callao NRB 305','Pilsen Callao RB 1000','San Juan CAN 355 x6','San Juan RB 620',
  'Stella Artois NRB 330'
)
GROUP BY `Agrupador (Sku)`, marca
ORDER BY brandpack, marca
LIMIT 200;
