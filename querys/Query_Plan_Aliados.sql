-----QUERY TRACKING PLAN ALIADOS-----------
Crea columnas para cada categoría de Volumen  Beer, Premium, Corona, SS, Candado SS.

WITH BASE_VENTA AS (

SELECT
  a.agrupador,
  a.mes,
  date_format(a.fecha_venta, 'dd') AS dia,
  a.direccion,
  a.gerencia,
  a.unidad_negocio_revenue AS UNegocio,
  a.subcanal_cliente,
  a.cliente_id,
  c.nombre,
  a.material_id,
  a.estratificacion,

  IFNULL(d.marca, 'Otros') AS marca,
  IFNULL(d.marca_gpa, 'Otros') AS marca_gpa,
  IFNULL(d.pack, 'Otros') AS pack,

  SUM(a.hl) AS HL,
  SUM(a.caja_fisica) AS CAFisc,
  SUM(a.gsi) AS GSI,
  SUM(a.excise) AS EXC,
  SUM(a.descuento) AS Disc,
  SUM(a.nr) AS NR,

  d.`Agrupador (Tipo 2.0)` AS KPI,
  IFNULL(e.estado, 'No Core') AS Pago_gsi,

  /* RANGO */
  CASE
    WHEN CAST(a.mes AS INT) = MAX(CAST(a.mes AS INT)) OVER ()
      THEN 'ACT'
    WHEN CAST(a.mes AS INT) = MIN(CAST(a.mes AS INT)) OVER ()
      THEN 'LY'
    ELSE 'LM'
  END AS rango,

  /* PREMIUM */
  CASE
    WHEN d.marca IN (
      'Cusqueña',
      'Corona',
      'Budweiser',
      'Stella Artois',
      'Flying Fish'
    )
    THEN '1'
    ELSE '0'
  END AS flag_premium,

  /* INNOVACIÓN / FRESH */
  CASE
    WHEN d.marca_gpa IN (
      'Corona Cero',
      'Cusqueña Cero',
      'Flying Fish',
      'P.Fresh'
    )
    AND a.material_id <> 0
    THEN '1'
    ELSE '0'
  END AS flag_Inno_fresh,

  /* CANDADO SS - CENTRO ORIENTE */
  CASE
    WHEN d.marca_gpa IN (
      'Corona Cero',
      'Cusqueña Cero',
      'Flying Fish',
      'P.Fresh'
    )
    AND a.material_id <> 0
    THEN '1'
    ELSE '0'
  END AS candado_ss_sj,

  /* SS - CENTRO ORIENTE */
  CASE
    WHEN d.marca <> 'Corona'
    AND d.`Agrupador (Tipo 2.0)` IN ('Latas')
    THEN '1'
    ELSE '0'
  END AS flag_ss,

  /* GLOBALES */
  CASE
    WHEN d.marca IN (
      'Corona',
      'Budweiser',
      'Stella Artois'
    )
    THEN '1'
    ELSE '0'
  END AS flag_gbrand,

  CASE
    WHEN d.marca IN (
      'Corona',
      'Budweiser',
      'Stella Artois'
    )
    THEN '1'
    ELSE '0'
  END AS pago_gbrand,

  /* CATEGORÍA */
  CASE
    WHEN a.estratificacion IN (
      'Cervezas',
      'Licores'
    )
    THEN '1'
    ELSE '0'
  END AS flag_categoria

FROM slv_maz_dataexperience_peru_dm.dm_venta a

LEFT JOIN slv_maz_dataexperience_peru_dm.dm_cliente c
  ON c.cliente_id = a.cliente_id

LEFT JOIN slv_maz_dataexperience_peru_revenue.revenue_maestro_sku d
  ON d.sku = a.material_id

LEFT JOIN slv_maz_dataexperience_peru_revenue.rev_lider_aliado_estado_whls e
  ON e.material_id = a.material_id

WHERE a.mes >= '202501'

  /* =====================================================
     SOLO CENTRO ORIENTE
     ===================================================== */
  AND a.direccion = 'PE Dir Centro Orient'
  AND  a.agrupador = 'Venta'
  AND a.estratificacion IN (
    'Cervezas',
    'Licores',
    'Ready To Drink'
  )

  AND a.estado_venta = '1'

  AND a.material_id <> '22868'

GROUP BY ALL
),

BASE_VENTA2 AS (

SELECT
  *,

  /* HL BEER */
  CASE
    WHEN Pago_gsi IN (
      'Core',
      'No Core',
      'CSQ6xx'
    )
    THEN HL
    ELSE 0
  END AS HL_BEER,

  /* HL PREMIUM */
  CASE
    WHEN flag_premium = '1'
    THEN HL
    ELSE 0
  END AS HL_PREMIUM,

  /* HL CANDADO */
  CASE
    WHEN candado_ss_sj = '1'
    THEN HL
    ELSE 0
  END AS HL_CANDADO,

  /* HL SS */
  CASE
    WHEN flag_ss = '1'
    THEN HL
    ELSE 0
  END AS HL_SS,

  /* HL GLOBALES */
  CASE
    WHEN flag_gbrand = '1'
    THEN HL
    ELSE 0
  END AS HL_Globales,

  /* GSI CORE */
  CASE
    WHEN Pago_gsi = 'Core'
    THEN GSI
    ELSE 0
  END AS GSI_Core,

  /* GSI NO CORE */
  CASE
    WHEN Pago_gsi = 'No Core'
    THEN GSI
    ELSE 0
  END AS GSI_No_Core,

  /* GSI CSQ6xx */
  CASE
    WHEN Pago_gsi = 'CSQ6xx'
    THEN GSI
    ELSE 0
  END AS GSI_CSQ6xx,

  /* GSI SS */
  CASE
    WHEN flag_ss = '1'
    THEN GSI
    ELSE 0
  END AS GSI_SS_Latas,

  /* GSI GLOBALES */
  CASE
    WHEN pago_gbrand = '1'
    THEN GSI
    ELSE 0
  END AS GSI_Globales

FROM BASE_VENTA

WHERE mes = '202608'

  /* SOLO CLIENTES ALIADOS */
  AND cliente_id IN (
    SELECT DISTINCT cliente_id
    FROM slv_maz_dataexperience_peru_revenue.revenue_dev_aliados
    WHERE mes = '202608'
  )
)

SELECT
  *
FROM BASE_VENTA2

GROUP BY ALL;