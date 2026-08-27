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
consultas SQL "finales"/curadas (para reejecutar o auditar despues) se guardan en `querys/`.

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
jerarquia vigente aplicada tambien al historico) en vez de `c.gerencia` (de `dm_cliente`).

**Reestructuracion de gerencias (inicios de 2026):** la direccion `PE Dir Oriente` paso a llamarse
**`PE Dir Centro Orient`** y sumo la GV Huancayo (antes `PE Ger P3 Huancayo` bajo la direccion
`PE Dir Centro Sur`, ahora `PE Ger P4 Huancay Ch` — es la GV listada arriba como
`PE Ger P4 Huancay Ch`). La direccion `PE Dir Centro Sur` paso a llamarse **`PE Dir Sur`** tras
perder esa GV. En `dm_venta`, los campos `direccion`/`gerencia` reflejan la jerarquia **nueva**
incluso para ventas historicas (antes de la reestructuracion); `direccion_historia`/
`gerencia_historia` y `direccion_venta`/`gerencia_venta` preservan la jerarquia **como era en el
momento real de la venta** (detalle completo y como usarlos en `BITACORA_TABLAS.md` →
`dm_venta`).

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

- **SKU Uptime** (KPI de la Liga Logistica, "Excelencia Comercial"): mide **cuantas horas el SKU
  estuvo "apagado" (no disponible) en BEES por falta de stock** — el foco del KPI es la rotura
  (horas apagadas), aunque se reporte como % de disponibilidad. **BEES es la app B2C de Backus**,
  usada por los clientes directos (POCs) para hacer sus pedidos — el KPI mide la experiencia de
  compra de ese cliente final, no un canal interno/mayorista. Formula:
  `Horas disponibles de SKUs en BEES / Horas disponibles en el mes`, donde el numerador es la
  sumatoria de horas que cada SKU estuvo "prendido" (disponible, i.e. NO apagado) por CD, y el
  denominador es `24h x #dias del mes x #SKUs x #CDs`. Ejemplo de la capacitacion: 2 CDs, 30 dias,
  3 SKUs → denominador 4,320h; con 2,000+2,160=4,160h disponibles → **96%** (equivale a 160h
  "apagadas" ese mes). Confirmado con foto de capacitacion interna (2026-08-23).
  **Ojo con el scope:** se considera todo el portafolio Backus, pero **el listado exacto de SKUs a
  medir cada mes lo define el equipo de Planning a inicio de mes** — no es "todo lo que hay en la
  tabla", es un input externo mensual que hay que conseguir aparte (no derivable solo de los
  datos).
  **Mapeo a Databricks:** misma tabla que `Brand Distribution` de stock/quiebres —
  `dev_onep_fact_critical_items_summary_24h_brand_pack_gold` (ver `BITACORA_TABLAS.md`). Se calcula
  como `SUM(horas_prendidas_brand_pack) / SUM(horas_disponibles)` sobre el scope de fechas/SKUs/CDs
  — **sumar numerador y denominador, no promediar `pct_uptime_brand_pack` fila por fila** (da un
  resultado distinto si los grupos no tienen el mismo peso).

- **Stock SAP** ("stock en piso"): cantidad de **cajas fisicas de stock** disponibles por material
  x Centro de Distribucion (CD), directo de SAP (fuente transaccional, replicada a Databricks).
  Reproduce la cascada de disponibilidad de la transaccion SAP `ZSMGEN_STOCK_DISP`:
  `Stock Disp (libre utilizacion) → -entregas pendientes → Total Disponible → -pedidos abiertos
  → Disponible Final → -reservas → CalDisFinal` (el mas conservador, descuenta compromisos
  futuros). Query base recibida de Data Engineering Peru (Javier) el 2026-07-09, a pedido del
  usuario — ver `querys/Query_Stocks_SAP.sql` (muy bien documentada, con la mecanica completa
  en los comentarios del archivo).
  **ADVERTENCIAS CRITICAS antes de usar estos numeros** (no son opcionales, condicionan si el dato
  sirve para la pregunta que se esta respondiendo):
  - **No es tiempo real** — es una foto de **inicio de dia** (el batch SAP→Databricks corre en la
    manana; MARD ~10:01am Peru, MCHB ~1pm). El stock fisico si cuadra a esa hora, pero
    pedidos/entregas se acumulan durante el dia — un caso validado en el query mostro una
    diferencia de **~1000x** entre "pedidos" de esta consulta vs. SAP en vivo el mismo dia (28 CA
    vs 27,191 CA). `Disponible_Final`/`CalDisFinal` son **referenciales de inicio de dia**, no ATP
    en tiempo real.
  - **Alcance de almacenes**: por defecto la consulta suma TODOS los almacenes del centro; la
    transaccion SAP real (`ZSMGEN_STOCK_DISP`) usa solo un subconjunto (~`IQ01` Prod. Terminados)
    — pendiente confirmar el set exacto con logistica antes de comparar 1 a 1 contra SAP.
  Mapeo a Databricks: catalogo `brewdat_uc_maz_prod` (replica SAP PR3) — ver `BITACORA_TABLAS.md`.

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

**Mapeo a Databricks — Drops:** ya identificado. La vista
`slv_maz_dataexperience_peru_revenue.revenue_dev_vw_rev_maestro_drops_brandpack` trae el resultado
de Drops ya calculado a grano cliente-brandpack (ver `querys/Query_Drops.sql`), filtrar por
`direccion`. Pendiente documentar el detalle de columnas en `BITACORA_TABLAS.md`.

**Pendiente de mapear:** SKU x POC y Cobertura todavia no tienen tabla/columna identificada
en Databricks — cuando se arme la primera consulta que calcule cada una, documentar el mapeo exacto
(que campos/joins se usaron) en `BITACORA_TABLAS.md`.

## Nomenclatura y siglas del negocio

Definiciones validadas por el usuario (2026-08-27):

- **PTR (Price To Retail):** precio al que Backus vende a sus clientes directos con codigo
  (bodegas, minimercados, licorerias, mayoristas, etc.). No existe como campo unico en `dm_venta`
  con ese nombre exacto — por eso las consultas propias calculan **`PTR_Final`** como campo
  derivado.
- **PTC (Price To Consumer):** precio al que el cliente de Backus (el POC) le vende al consumidor
  final.
- **VIC (Variable Industrial Cost):** linea del P&L — costo de **producir** el producto.
- **VLC (Variable Logistic Cost):** linea del P&L — costo de **entregar** el producto.
- **Porte:** interes que Backus cobra al cliente por venderle a credito (no al contado). Tasas
  sobre el precio final de factura: **7 dias → 2.05%**, **14 dias → 3.15%**.
- **KKAA (Key Accounts):** cuentas clave — es uno de los canales (ver mapeo
  `unidad_negocio_revenue_volumen_meta` en `BITACORA_TABLAS.md` → `dm_cliente`). Los campos
  `kkaa_kam`/`kkaa_cadena`/`kkaa_manager`/`kkaa_coordinador` de `dm_cliente` son la estructura de
  gestion de este canal.
- **OBPPC (Occasion, Brand, Package, Price, Channel):** framework/estrategia de Revenue Growth
  Management — no es un campo de negocio suelto, es la logica detras de campos como
  `Price_Segment_OBPPC`, `obppc_stage`, `obppc_cluster`.
- **BEES:** app de Backus para que los clientes (POCs) hagan sus pedidos.
- **CD (Centro de Distribucion) / Centro:** almacen fisico establecido en una zona/localidad. **Un
  CD puede abastecer a mas de una GV** (relacion no es 1:1) — ver ejemplo en `BITACORA_TABLAS.md`
  (CD Pucallpa/`SJ97` reparte a las 4 GV de Centro Oriente).
- **GV (Gerencia de Ventas)** = `gerencia`. La Regional Centro Oriente tiene **5 GV**. Una GV puede
  recibir de 1 o mas CD.
- **HL (Hectolitro):** unidad de medida de volumen de Backus, **1 HL = 100 litros**. La conversion
  caja→HL varia por SKU/formato. Ejemplo confirmado (Cristal 650 x12): `0.650 L/botella x 12
  botellas/caja = 7.8 L/caja` → `7.8 / 100 = 0.078 HL/caja`.
- **CA / CF (Caja Fisica):** unidad de empaque del producto — varia por SKU (ej. cervezas de mayor
  litraje como Cristal 650, Pilsen 630, San Juan 620, Cusqueña 620 vienen en caja de 12 unidades;
  latas en six-packs de 6 unidades).
- **CE / CEQ (Caja Equivalente):** operacion interna de estandarizacion de volumen entre distintos
  formatos de caja fisica (formula exacta aun no validada — tratar como pendiente si un analisis
  depende de la formula precisa).
- **Nomenclatura de SKU:** el nombre de material suele seguir el patron `Marca + Mililitraje x
  Unidades por caja fisica`, ej. `Cristal 650 x12`, `Pilsen 630 x12`.

## Procesos de negocio

- **Ciclo de un pedido de venta** (preventa → pedido → facturacion): primero se hace la
  **preventa** (1 a 7 dias antes de la entrega); el **pedido** es cuando ya se le asigna camion y
  fecha de entrega en el sistema; la **facturacion** es cuando el producto ya fue entregado y el
  cliente pago. Ver `clase_venta` en `dm_venta` (`BITACORA_TABLAS.md`) para los codigos SAP de cada
  etapa/tipo de documento.

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
