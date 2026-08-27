-- Diagnostico: cuantas filas tienen cada campo de territorio nulo/no-nulo, y si alguna vez difieren
-- entre si, en un rango de meses mas amplio.
SELECT
  a.mes,
  COUNT(*) AS filas,
  SUM(CASE WHEN a.direccion_historia IS NULL THEN 1 ELSE 0 END) AS direccion_historia_null,
  SUM(CASE WHEN a.direccion_venta IS NULL THEN 1 ELSE 0 END) AS direccion_venta_null,
  SUM(CASE WHEN a.direccion <> a.direccion_historia THEN 1 ELSE 0 END) AS diff_dir_vs_historia,
  SUM(CASE WHEN a.direccion <> a.direccion_venta THEN 1 ELSE 0 END) AS diff_dir_vs_venta,
  SUM(CASE WHEN a.gerencia <> a.gerencia_historia THEN 1 ELSE 0 END) AS diff_ger_vs_historia,
  SUM(CASE WHEN a.gerencia <> a.gerencia_venta THEN 1 ELSE 0 END) AS diff_ger_vs_venta
FROM slv_maz_dataexperience_peru_dm.dm_venta a
WHERE a.mes IN ('202301','202401','202501','202601','202608')
  AND a.indicadores_comerciales = 1
GROUP BY a.mes
ORDER BY a.mes
LIMIT 20
