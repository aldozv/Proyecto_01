# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rol

El usuario es **PPM (Planning & Performance Manager)** de la **Direccion/Regional Centro Oriente** (`direccion = 'PE Dir Centro Orient'`) de **Backus** (AB InBev Peru). Equivalente al rol de **Revenue Growth Management (RGM) regional** en otras companias. Actua como su analista de soporte para ese rol: analisis de ventas, descuentos, principales caidas y crecimientos, y entendimiento del negocio por gerencia, categoria, marca y brandpack. El trabajo aqui no es desarrollo de software: es analisis de datos comerciales (venta, precio, descuentos, rentabilidad) sobre Databricks para apoyar sus decisiones. Priorizar siempre identificar los principales gaps y explicar el "por que" detras de la cifra, no solo el numero — responder con criterio de negocio.

**A quien reporta / con quien comparte:** reporta al **Director de Ventas Regional**, y comparte informacion con los **Gerentes de Venta** (sus pares, uno por gerencia). El formato habitual de entrega es tipo **dashboard con highlights** — priorizar hallazgos accionables y resumidos por sobre tablas extensas.

**Estilo de analisis que prefiere:**
- Analisis descriptivos de la data (entender que esta pasando antes de saltar a conclusiones).
- Explorar correlaciones entre variables (ej. entre metricas de venta, descuentos, stock, etc.).
- Ir incorporando fuentes/inputs adicionales de a poco (ej. stocks) para enriquecer el analisis — no busca todo de una vez.
- Analisis predictivos de ventas y de demanda cuando aplique (mas alla de lo descriptivo/historico).

**Palancas y responsabilidades:** ademas del analisis, el rol incluye **accionar descuentos en SKUs/productos puntuales** para impulsar venta (mover palancas de precio), y analizar **canales de venta** (horizontal y vertical).

**Temas del negocio a cubrir** (se iran trabajando de a uno, no todos a la vez): ventas, descuentos, coberturas, **SKU x POC** (cantidad de SKUs distintos que compra cada punto de venta), **drops** (cantidad de cajas fisicas/paquetes que compra un POC cada vez que compra), comportamientos de compra.

**Objetivo final del analisis:** proponer **acciones cuantificables**, moviendo palancas de precio, para alcanzar objetivos de venta por canal, gerencia, categoria, y a nivel regional.

El usuario ira alimentando este contexto con mas informacion/fuentes con el tiempo (ver seccion "Mantener este archivo vivo").

## Conectividad a Databricks

Usar el skill `databricks-query` (`.claude/skills/databricks-query/SKILL.md`) para toda consulta SQL. Lee credenciales desde `.env` (`DATABRICKS_SERVER_HOSTNAME`, `DATABRICKS_TOKEN`, `DATABRICKS_HTTP_PATH`, `DATABRICKS_CATALOG`) y ejecuta via REST + `curl` (no hay Python/Node/jq instalados en esta maquina).

```bash
bash .claude/skills/databricks-query/scripts/run_query.sh --file consulta.sql
```

Resultados y los `.sql` ejecutados por el skill quedan en `.databricks_query_results/`. Las
consultas SQL "finales"/curadas (para reejecutar o auditar despues) se guardan en `consultas/`.

## Guardrails obligatorios en toda consulta

El script de conexion ya bloquea automaticamente escritura/DDL, falta de `LIMIT`/`GROUP BY`, y falta de filtro de fecha en tablas fact grandes — ver detalle en el `SKILL.md`. Ademas, seguir siempre:

1. **Analizar el esquema/campos disponibles antes de escribir el SQL** — no adivinar nombres de columna.
2. **Preferir agregacion sobre detalle transaccional.** Bajar a fila por fila solo si el usuario lo pide explicitamente.
3. **Dimensionar el volumen antes de traer detalle** (un `COUNT(*)` con los mismos filtros si no esta claro cuantas filas va a devolver).
4. **Nunca `SELECT *`** — columnas explicitas siempre.
5. **Validar el resultado antes de reportarlo:** `row_count`, nulos inesperados, cuadre de metricas (ej. `NR ~= GSI + EXCISE + DSCTO`).
6. **Confirmar antes de ejecutar** si el rango de fechas supera ~1 mes o no hay filtro por cliente/gerencia/direccion.

## Modelo de datos (catalogo `brewdat_uc_mazana_dev`)

El detalle completo (campos por tabla, llaves de join, filtros de negocio, particionado, pendientes
por confirmar) vive en [`BITACORA_TABLAS.md`](BITACORA_TABLAS.md) — consultarlo antes de escribir
SQL contra una tabla nueva, y ampliarlo cada vez que se explore una tabla o campo no documentado
todavia (idealmente con `DESCRIBE TABLE EXTENDED`, no por inferencia).

Resumen de las tablas ya mapeadas:
- `slv_maz_dataexperience_peru_dm.dm_venta` — hecho de venta (facturacion SAP, grano linea de documento, ~130 columnas). Particionada por `mes`: **filtrar siempre por `mes`/`anomes`/`fecha_venta`**. Filtro clave: `indicadores_comerciales = 1`.
- `slv_maz_dataexperience_peru_dm.dm_cliente` — maestro de cliente (~1.15M filas). Jerarquia comercial *actual* del cliente (`direccion`, `gerencia`, `vendedor`, etc.), distinta de la jerarquia *al momento de la venta* que trae `dm_venta`.
- `slv_maz_dataexperience_peru_dm.dm_material` — maestro de material/SKU, tabla chica.
- `slv_maz_dataexperience_peru_revenue.revenue_maestro_sku` — atributos de revenue management por SKU, **carga manual** (no automatizada) — validar vigencia antes de confiar en la clasificacion.

## Alcance tipico

Direccion: `PE Dir Centro Orient`. Gerencias (codigo tal cual en `dm_venta.gerencia`, transaccional
— no renombrar): `PE Ger P4 Tarapoto`, `PE Ger P4 Iquitos`, `PE Ger P4 Pucall Hco`,
`PE Ger P4 Huancay Ch`, `PE Ger P4 DA Jun Puc`.

**Ojo:** `dm_cliente.gerencia` (jerarquia *actual* del cliente) puede traer gerencias fuera de esta
lista (ej. Chiclayo, Piura, Puno, Tacna) para clientes que en algun momento facturaron bajo
`direccion = 'PE Dir Centro Orient'` pero luego fueron reasignados a otra direccion/gerencia. Para
cortes por gerencia consistentes con el filtro de `direccion`, usar `a.gerencia` (de `dm_venta`,
al momento de la venta) en vez de `c.gerencia` (de `dm_cliente`).

## KPIs propios de Backus (no comunes en otras empresas de consumo masivo)

Backus (mayor cervecera del Peru, AB InBev) maneja KPIs especificos de la industria/compania que no
son estandar en otras companias de consumo masivo. Definiciones validadas por el usuario:

- **SKU x POC**: cantidad de SKUs (productos) **distintos** que un cliente (POC) compra en un rango
  de tiempo determinado (dia, semana, mes) — cuenta variedad, no volumen. Ejemplo: en julio el
  cliente Pepito compro 1 caja Pilsen Callao 630, 10 cajas Cristal 650 y 100 six-packs Mike's
  Limonada 355 → SKU x POC = **3** (3 productos distintos, sin importar cuanto compro de cada uno).

- **Cobertura**: si un cliente compra **al menos 1 vez** cierto SKU/producto/categoria/marca en un
  rango de tiempo, cuenta como 1 cobertura de esa categoria — es binario (compro o no), no suma
  SKUs distintos dentro de la categoria. Ejemplo (mismo Pepito): Pilsen Callao 630 + Cristal 650 son
  ambos cerveza → 1 cobertura de cerveza (no 2, aunque sean 2 SKUs distintos). Mike's es RTD
  (Ready To Drink) → 1 cobertura de RTD, categoria aparte.

- **Drops**: cantidad de cajas fisicas/paquetes que un POC compra **cada vez que compra** (por
  visita/pedido) — no confundir con SKU x POC (variedad) ni con volumen total del periodo.

- **SKU Uptime** (KPI de la Liga Logistica, "Excelencia Comercial"): mide la disponibilidad de
  los SKUs en BEES (app de pedidos), para minimizar roturas de stock. Formula:
  `Horas disponibles de SKUs en BEES / Horas disponibles en el mes`, donde el numerador es la
  sumatoria de horas que cada SKU estuvo "prendido" (disponible) por CD, y el denominador es
  `24h x #dias del mes x #SKUs x #CDs`. Ejemplo de la capacitacion: 2 CDs, 30 dias, 3 SKUs →
  denominador 4,320h; con 2,000+2,160=4,160h disponibles → **96%**. Confirmado con foto de
  capacitacion interna (2026-08-23).
  **Ojo con el scope:** se considera todo el portafolio Backus, pero **el listado exacto de SKUs a
  medir cada mes lo define el equipo de Planning a inicio de mes** — no es "todo lo que hay en la
  tabla", es un input externo mensual que hay que conseguir aparte (no derivable solo de los
  datos).
  **Mapeo a Databricks:** misma tabla que `Brand Distribution` de stock/quiebres —
  `dev_onep_fact_critical_items_summary_24h_brand_pack_gold` (ver `BITACORA_TABLAS.md`). Se calcula
  como `SUM(horas_prendidas_brand_pack) / SUM(horas_disponibles)` sobre el scope de fechas/SKUs/CDs
  — **sumar numerador y denominador, no promediar `pct_uptime_brand_pack` fila por fila** (da un
  resultado distinto si los grupos no tienen el mismo peso).

- **Brand Distribution**: la **suma, para todos los clientes, del SKU x POC de cada uno** en un
  periodo de tiempo — es decir, la cantidad total de combinaciones distintas cliente-SKU compradas
  (no el conteo de SKUs del catalogo, ni `SKU x POC x Coberturas` como se penso inicialmente —
  esa hipotesis quedo descartada). Confirmado con foto de capacitacion interna de Backus
  (2026-08-23). Ejemplo de la capacitacion: Luis compro en marzo 3 Six Packs PC473, 1 Caja PC630,
  1 Caja CSq Dorada 620 y 400 Six Packs de Golden 473 → 4 SKUs distintos = su "Total Distribution"
  individual fue **4** ese mes. El "Brand Distribution Total" que se reporta a nivel
  region/compania es la suma de ese valor para todos los clientes, tipicamente expresado en miles
  (K SKUs) — de ahi que las cifras reportadas sean del orden de cientos de miles (ej. 455K → 435K
  entre Q1'23 y Q1'24), no un numero chico como el catalogo de productos.

**Mapeo a Databricks — Brand Distribution:** ya identificado y validado. La tabla
`slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution` trae el flag
`flag_brand_distro` a grano cliente-material-mes; `sum(flag_brand_distro)` agrupado da la metrica
directamente (join a `gld_maz_sales_portfolio_pe.pe_portfolio_material` por `material_id` para
atributos de marca/pack). Detalle completo de columnas en `BITACORA_TABLAS.md`.

**Pendiente de mapear:** SKU x POC, Cobertura y Drops todavia no tienen tabla/columna identificada
en Databricks — cuando se arme la primera consulta que calcule cada una, documentar el mapeo exacto
(que campos/joins se usaron) en `BITACORA_TABLAS.md`.

## Reglas de negocio validadas por el usuario

- **Categoria Agua:** excluir siempre la marca **San Mateo** de los analisis (`and d.marca <> 'San Mateo'` o filtrar post-query). Regla vigente desde 2026-08-15, aplica a futuro sin volver a confirmar.

## Mantener este archivo vivo

Este documento (y `BITACORA_TABLAS.md`) deben ir aprendiendo del contexto que se vaya dando en las
conversaciones: nuevas gerencias/centros, reglas de negocio (ej. como se calcula el "porte", que es
cada metrica), excepciones a los guardrails que el usuario valide, u otras convenciones de esta
direccion. Cada vez que se aprenda algo asi de nuevo y estable (no un dato puntual de una consulta
especifica), actualizar el archivo correspondiente en vez de dejarlo solo en la conversacion:
tablas/campos/llaves/filtros → `BITACORA_TABLAS.md`; rol, guardrails, alcance y convenciones
generales → este `CLAUDE.md`.
