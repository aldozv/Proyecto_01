# Bitacora de tablas — Databricks (catalogo `brewdat_uc_mazana_dev`)

Catalogo de tablas que se van conociendo, con foco en lo util para analisis comercial:
llaves, filtros de negocio y campos que se usan seguido. Se alimenta con `DESCRIBE TABLE EXTENDED`
(metadata real, no inferencia) mas lo que se va aprendiendo en cada consulta. Actualizar esta
bitacora cada vez que se explore una tabla nueva o se descubra un campo/regla de negocio relevante.

---

## `slv_maz_dataexperience_peru_dm.dm_venta` — Hecho de venta

**Que es:** Facturacion de SAP a nivel linea de documento. Frecuencia diaria, data hasta d-1
(segun comentario de la tabla). ~130 columnas.

**Particionado/clustering:** por `mes` (string, formato `yyyymm`, ej. `202607`). **Siempre filtrar
por `mes`/`anomes` (o `fecha_venta`) — sin este filtro el warehouse escanea todo el historico.**
Esto ya lo exige el guardrail del skill `databricks-query`.

**Llave de negocio / grano:** linea de documento (`numero_documento_venta` + `posicion_venta`
aprox.). Para agregados de negocio normalmente se agrupa por `cliente_id`, `material_id`, `mes`.

**Llaves de join:**
- `cliente_id` → `dm_cliente.cliente_id`
- `material_id` → `dm_material.material_id`
- `material_id` → `revenue_maestro_sku.sku`

**Filtros de negocio importantes:**
- `indicadores_comerciales = 1` — clave: filtra solo lo que cuenta para KPIs comerciales oficiales.
  Usar por defecto salvo que el analisis pida explicitamente lo excluido.
- `agrupador` — tipo de movimiento: `'Venta'`, `'Nota De Crédito'`, etc. Para venta neta hay que
  decidir si se incluyen las notas de credito (son negativas) o se filtra solo `'Venta'`.
- `estratificacion` — categoria de bebida: `Cervezas`, `Licores`, `Ready To Drink`, `Gaseosas`,
  `Agua`, `Maltas`.
- `estado_venta` — estado de la linea (revisar valores validos antes de asumir).
- `clase_venta` — tipo de documento SAP. Valores conocidos: `ZPP1` preventa flujo1, `ZPP3` pedido
  de venta, `ZPO1`/`ZPO3` obsequio, `ZPO6` preventa-canje, `ZPO7` venta-canje, `ZPPV`/`ZPOB` pedido
  de oficina, `ZPP5` EDI, `ZPD1/ZPD3/ZPD5/ZPD6`/`BKNC`/`ZPDF`/`ZPDB` notas de credito.
- `direccion` / `gerencia` — jerarquia territorial **vigente/actual, aplicada tambien de forma
  retroactiva al historico**. Tambien existen `direccion_historia`/`gerencia_historia` y
  `direccion_venta`/`gerencia_venta`, que preservan la jerarquia **tal como era al momento real de
  la venta** (antes de reestructuraciones). **Confirmado por el usuario (2026-08-27) — hubo una
  reestructuracion de gerencias a inicios de 2026:** la direccion `PE Dir Oriente` paso a llamarse
  **`PE Dir Centro Orient`** y **sumo la GV Huancayo** (antes `PE Ger P3 Huancayo`, ahora
  `PE Ger P4 Huancay Ch`), que pertenecia a la direccion `PE Dir Centro Sur` — esta ultima paso a
  llamarse **`PE Dir Sur`**. Esto explica el ejemplo validado con datos: para una venta real de
  202501 (antes de la reestructuracion) del cliente 11564439, `direccion`/`gerencia` muestran la
  jerarquia **nueva** (`PE Dir Centro Orient` / `PE Ger P4 Huancay Ch`) mientras que
  `direccion_historia`/`gerencia_historia` y `direccion_venta`/`gerencia_venta` muestran la
  jerarquia **como era en ese momento** (`PE Dir Centro Sur` / `PE Ger P3 Huancayo`) — ambas
  variantes coincidieron entre si en ese caso, pero **el usuario confirmo (2026-08-28) que
  `direccion_historia`/`gerencia_historia` y `direccion_venta`/`gerencia_venta` NO siempre
  coinciden entre si** — queda pendiente identificar un caso concreto de divergencia para entender
  que distingue a cada una (ver seccion "Pendiente de confirmar").
  Tambien explica por que `direccion_historia` dejo de poblarse desde 202601 (mes en que entro en
  vigencia la nueva estructura: ya no hay "historia" distinta que preservar para ventas nuevas) y
  por que la divergencia entre `direccion` y las otras dos variantes desaparecio desde ese mes
  (~27-30% de filas distintas en 2023-2025, 0 en 202601/202608).
  **Implicancia practica:** para comparar series historicas con la jerarquia territorial vigente
  (ej. "todo lo que hoy es Centro Oriente, incluyendo Huancayo, aunque en su momento fuera Centro
  Sur"), usar `direccion`/`gerencia`. Para reconstruir como se veian los resultados **en el momento
  real** de cada periodo (ej. reportar Centro Sur tal como era antes de perder Huancayo), usar
  `direccion_historia`/`gerencia_historia` o `direccion_venta`/`gerencia_venta`.

**Campos que solemos usar:** `cliente_id`, `direccion`, `gerencia`, `centro` (via `dm_cliente`),
`material_id`, `fecha_venta`, `mes`/`anomes`, `semana`, `semana_dia`, `estratificacion`,
`agrupador`, `numero_documento_venta`.

**Metricas principales:** `hl`, `caja_fisica`, `caja_equivalente`, `gsi`, `excise`, `descuento`
(desglosado en `descuento_canal`/`descuento_promocion`/`descuento_combo`), `nr`, `ptr`, `ptc`,
`porte`, `vic`, `vlc`, `maco`, `subtotal`, `valor_venta`, `valor_neto`, `isc`, `igv`, `total`.
Regla observada en la query original: `NR = GSI + EXCISE + DSCTO` (descuento ya viene en negativo).

**Metadata:** creada 2025-02-06, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_dm.dm_cliente` — Maestro de cliente

**Que es:** Maestro/atributos de cliente. ~1,151,927 filas (~137 MB). **Confirmado con datos
(2026-08-27): es un snapshot UNICO, no historico** — el campo `mes` trae un solo valor en toda la
tabla (`202608`, el mes vigente al momento de la consulta), no una fila por cliente por mes. Por lo
tanto join a `dm_venta` por `cliente_id` trae siempre la ficha **actual** del cliente (CD, canal,
gerencia, etc.), sin importar el mes historico de la venta — no hace falta (ni es posible) filtrar
`dm_cliente.mes` para "alinear" con el mes de `dm_venta`. Ojo con este punto en analisis
multi-anio: un cliente que cambio de CD/canal/gerencia en el periodo aparece siempre bajo su
clasificacion actual, incluso para ventas historicas.

**Llave de negocio:** `cliente_id`.

**Campos que solemos usar:** `nombre`, `gerencia`, `centro`/`centro_id` (CD — `dm_venta` NO trae
centro/CD directamente, solo se obtiene via join a `dm_cliente`), `unidad_negocio_revenue_volumen_meta`
(canal "meta", ver mapeo abajo).

**Mapeo `unidad_negocio_revenue_volumen_meta` → canales PPM (validado con datos, gerencia
Pucallpa):** este es el campo al que el usuario se refiere informalmente como "unidad_negocio_meta"
para su clasificacion de canales. Valores observados y su equivalencia con la nomenclatura del rol
(ver CLAUDE.md → "Rol"): `DSD OFF`, `DSD ON`, `Mayoristas` (= WHL), `Eventos` (= EVE),
`Key Accounts` (= KA), `DAs` (= DAS), y un residual `High End` (no forma parte de los 6 canales
que maneja el usuario, volumen marginal). **No confundir con `dm_venta.unidad_negocio_venta`**
(u `unidad_negocio`/`unidad_negocio_revenue`), que es un campo distinto con otro dominio de valores
(`Off Premise`, `On Premise`, `Mayoristas y Eventos`, `Key Accounts`, `Consumidor`, `DAs`) — no sirve
para este mapeo de canal.

**Otros campos utiles para segmentacion/analisis:**
- Jerarquia comercial **actual** del cliente: `direccion`, `director`, `gerencia`, `gerente`,
  `subgerencia`, `supervisor`, `vendedor`, `zona_pem`, `zona_comisional`, `zona_venta`.
- Canal: `canal`, `subcanal`, `subcanal_local`, `subcanal_regional`.
- Segmentacion: `bees_segmento`, `obppc_stage`, `obppc_cluster`, `arquetipo_prioridad_1/2`.
- Ubicacion: `departamento`, `provincia`, `distrito`, `direccion_geo`, `localidad`.
- Estado/vigencia: `estado`, `fecha_alta`, `fecha_baja`, `indicadores_comerciales`.
- Comercial/credito: `linea_credito`, `cxc_liq_perc`, `cxc_envase`, `puntos`, `club_b`.
- KKAA (cuentas clave): `kkaa_kam`, `kkaa_cadena`, `kkaa_manager`, `kkaa_coordinador`.

**Nota clave:** la jerarquia territorial de este maestro (actual) puede diferir de la que trae
`dm_venta` al momento historico de la venta (`direccion_historia`/`gerencia_historia`). Para
reportes de evolucion en el tiempo, aclarar con el usuario cual criterio de territorio aplica.

**Metadata:** creada 2025-02-05, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_dm.dm_material` — Maestro de material/SKU

**Que es:** Maestro de producto/material. ~20 columnas, tabla chica.

**Llave de negocio:** `material_id` (mismo dominio que `dm_venta.material_id` y
`revenue_maestro_sku.sku`).

**Campos que solemos usar:** `nombre` (nombre del SKU).

**Otros campos utiles:** `estratificacion`, `marca`, `familia`, `pack`, `presentacion`,
`unidades_caja`, `volumen`, `tipo_envase`, `peso_bruto`/`peso_neto`, `estado`.

**Metadata:** creada 2025-02-05, owner `javier.armando.diaz@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_revenue.revenue_maestro_sku` — Maestro de Revenue Management por SKU

**Que es:** Atributos de clasificacion para revenue management, mantenida manualmente
("Created by the file upload UI" — **es una tabla de carga manual, no automatizada**: verificar
fecha de la ultima actualizacion antes de confiar en la clasificacion si el analisis es sensible
a cambios recientes de portafolio).

**Llave de negocio:** `sku` (= `material_id` de `dm_venta`/`dm_material`).

**Campos que solemos usar:** `marca`, `marca_gpa`, `pack`, `` `Agrupador (Sku)` ``,
`` `Agrupador (Tipo 2.0)` ``, `kpi_premium`, `ms_ss` (multipack `MS` vs single-serve `SS`).

**Otros campos utiles:** `categoria`, `segmento`, `Rol`, `envase`, `capacidad`,
`` `Agrupador (Tipo)` ``, `` `Agrupador (C/NC)` ``, `Price_Segment_OBPPC`, `` `Premium+Inno` ``,
banderas de innovacion (`Innovacion`, `Innovation`, `Innovation_1/2`, `Delivery`).

**Nota:** varios nombres de columna llevan espacios/parentesis (ej. `` `Agrupador (Sku)` ``) —
siempre usar backticks en el SQL.

**Campo `pack` (formato):** usado como "Formato" en el dashboard GV Volumen. Join
`dm_venta.material_id = revenue_maestro_sku.sku`. **Cobertura validada 2026-08-27** para las 4
gerencias de Centro Oriente (excl. estratificaciones fuera de alcance, San Mateo excluido):
**100% de las filas matchean** (0 HL en "Sin mapear") sobre 32 meses de historia — la carga
manual esta al dia para este alcance. Cardinalidad manejable: 20-24 valores distintos de `pack`
por gerencia (~22 en total). Revalidar esta cobertura si se corre para un periodo/alcance nuevo
y aparece volumen relevante sin mapear.

**Metadata:** creada 2025-02-05, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution` — Hecho de Brand Distribution

**Que es:** tabla pre-calculada del KPI **Brand Distribution** (ver definicion en `CLAUDE.md` →
"KPIs propios de Backus") a grano cliente-material-mes. Trae el flag `flag_brand_distro` (int):
sumarlo agrupado por gerencia/marca/mes/etc. da directamente la metrica — validado corriendo la
consulta con un mes de datos (`sum(flag_brand_distro)` da valores del orden de cientos por
combinacion marca/gerencia, consistente con la definicion de la capacitacion). Catalogo:
`brewdat_uc_mazana_dev` (mismo catalogo que `dm_venta`, database distinta).

**Particionado:** por `mes`.

**Campos:** `mes`, `direccion`, `gerencia`, `fecha_venta` (date), `tipo` (ej. `SELLIN`), `cliente_id`,
`material_id`, `hl` (decimal), `flag_brand_distro` (int), `marca_tarea`, `marca_offer`,
`flag_comparable` (int).

**Llaves de join:** `material_id` → `pe_portfolio_material.material_id` (ver tabla siguiente —
catalogo distinto).

**Nota:** no tiene columna `indicadores_comerciales` (esa es propia de `dm_venta`/`dm_cliente`) —
no asumir ese filtro aca.

**Metadata:** creada 2024-12-10, owner `lizbeth.leon@gmodelo.com.mx`, formato Delta, tabla EXTERNAL.

---

## `gld_maz_sales_portfolio_pe.pe_portfolio_material` — Maestro de material para portfolio/Brand Distribution

**Que es:** maestro de producto usado para analisis de portfolio (marca, pack, categoria de
innovacion, etc.), usado junto con la tabla de Brand Distribution de arriba. **Ojo: vive en un
catalogo distinto** — `brewdat_uc_maz_scus_weu_sales_dev_ds` (no `brewdat_uc_mazana_dev`) — no
confundir con `dm_material`, que es otro maestro de producto separado.

**Llave de negocio:** `material_id`.

**Campos utiles:** `brand`, `brand_detailed`, `pack`, `package`, `brand_pack`,
`brand_pack_detailed`, `brand_pack_pop`, `category`, `item_category`, `brand_pack_smdc`/`smdc2`,
`category_growth`, `mission_name`, `estratificacion`, `brand_category`, `category_inno`,
`flag_inno`, `category_mktp`, `flag_activacion`, `flag_comparable`, `flg_activo_bees`.

**Metadata:** creada 2025-08-04, owner `brewdat-gb-it-p-superuser-s-w`, formato Delta, tabla
MANAGED.

---

## `dev_onep_fact_critical_items_summary_24h_brand_pack_gold` — Quiebres de stock (OOS) por brand_pack/CD

**Que es:** hecho de **quiebres de stock (Out of Stock) en BEES** (app B2C de Backus para clientes
directos/POCs) a nivel brand_pack + Centro de Distribucion (CD) + dia. Mide cuantas horas el SKU
estuvo "apagado" (no disponible para pedido) en BEES por falta de stock. Fuente del KPI
**SKU Uptime** (ver `CLAUDE.md` → "KPIs propios de Backus") — primer input de este tipo que se
incorpora al analisis (ver "Estilo de analisis que prefiere" en `CLAUDE.md`: ir sumando fuentes
como stocks de a poco). Columnas ya vienen documentadas con `comment` en Databricks (poco comun,
aprovechar esos comentarios en vez de adivinar).

**Ojo — se accede por ruta de Volume, no `catalogo.schema.tabla`:**
```sql
select ... from delta.`/Volumes/brewdat_uc_mazana_dev/slv_maz_dataexperience_peru_data/workspace/growth/dev_onep_fact_critical_items_summary_24h_brand_pack_gold`
```

**Particionado:** por `mes` (formato `YYYYMM`).

**Grano:** `mes` + `out_of_stock_date` + `centro_id` + `brand_pack`.

**Campos:**
- `mes` (string) — mes del evento, `YYYYMM`.
- `out_of_stock_date` (date) — fecha calendario del evento de quiebre.
- `centro_id` (string) — codigo del Centro de Distribucion (CD), formato `BK##`/`SJ##` (ej. `BK31`,
  `SJ90`). **Cruza con `dm_cliente.centro_id`** (mismo formato/dominio, confirmado con datos —
  ojo, no es `dm_cliente.centro`, que trae el nombre tipo `CD Huánuco` y es un campo distinto).
  **No hay relacion 1:1 con gerencia**: un mismo CD reparte a varias gerencias (ej. `SJ97`/CD
  Pucallpa reparte a las 4 gerencias de Centro Oriente) — se puede filtrar esta tabla a la lista de
  centros que sirven a una direccion/region, pero **no se puede atribuir un quiebre a una sola
  gerencia** con esta tabla sola.
- `brand_pack` (string) — marca + presentacion (ej. `Cristal 620 RB`).
- `activo_en_cd` (int) — 1 si al menos un SKU del brand_pack esta activo en el CD.
- `cant_skus_brand_pack` (int) — cantidad de SKUs distintos del brand_pack en el CD/dia.
- `horas_disponibles` (double) — ventana de disponibilidad, siempre 24.
- `horas_oos_brand_pack` (double) — horas OOS a nivel brand_pack (con logica de sustitucion).
- `horas_prendidas_brand_pack` (double) — horas sin quiebre (`24 - horas_oos`).
- `pct_horas_oos_brand_pack` (double, 0-1) — % de horas en quiebre.
- `pct_uptime_brand_pack` (double, 0-1) — % de tiempo disponible ("Uptime").
- `hl_so_brand_pack` (double) — **volumen estimado perdido (HL) por el quiebre** — conecta el
  quiebre directo con venta perdida, muy relevante para el objetivo de acciones cuantificables.
- `hl_pv_promedio_bp` (double) — promedio de HL/hora a nivel brand_pack (ultimos 6 meses).
- `flag_preventa_dia` (int) — 1 si hubo preventa del brand_pack ese dia (ultimos 6 meses).
- `max_length_of_time_days` (int) — maxima duracion de evento OOS en el grupo (dias).
- `skus_en_quiebre` (bigint) — cantidad de SKUs distintos con evento OOS valido en el dia.
- `fecha_proceso_dbks` (string) — timestamp de ejecucion del ETL.
- `skus_brand_pack_list` / `skus_oos_list` (string) — listas de SKUs (separadas por coma).

**Metadata:** catalogo `brewdat_uc_mazana_dev`, formato Delta, tabla MANAGED via Volume (sin fecha
de creacion/owner expuestos por `DESCRIBE EXTENDED` en este tipo de tabla).

---

## Catalogo `brewdat_uc_maz_prod` — Replica SAP PR3 (fuente del KPI Stock SAP)

**Que es:** catalogo distinto a `brewdat_uc_mazana_dev` (venta/cliente) y a
`brewdat_uc_maz_scus_weu_sales_dev_ds` (portfolio material) — aca vive la **replica cruda de
tablas SAP** (prefijo `copecac_*`, via CDC/Change Data Capture desde SAP PR3). Query base
recibida de Data Engineering Peru (Javier) el 2026-07-09 — ver
`querys/Query_Stocks_SAP.sql` para la mecanica completa (esta muy bien comentada, no
reinventar). Reconstruye la cascada de disponibilidad de la transaccion SAP `ZSMGEN_STOCK_DISP`
(ver definicion del KPI **Stock SAP** en `CLAUDE.md` — incluye advertencias criticas de frescura
y alcance de almacenes que hay que leer antes de usar estos numeros).

**Convenciones que aplican a TODAS las tablas `copecac_*`:**
- `op_ind <> 'D'` — excluir siempre el borrado logico del CDC.
- `matnr` (material SAP) viene como string con ceros a la izquierda — castear a `INT` para joins.
- Dos tipos de tabla:
  - **Estado-vigente** (`copecac_marm`, `copecac_mara`, `copecac_makt`, `copecac_mchb`): se puede
    sumar/agrupar directo.
  - **CDC append-log** (`copecac_vbbe`, `copecac_resb`): traen el historial completo de cambios,
    no solo el estado actual — hay que reconstruir el vigente con
    `ROW_NUMBER() OVER (PARTITION BY <PK> ORDER BY target_apply_ts DESC, header__change_seq DESC)`,
    quedarse con `rn = 1` y `op_ind IN ('I','U')`.

**Tablas usadas en la cascada de stock:**
- `slv_maz_masterdata_sap_pr3.copecac_marm` — conversion de unidades. `umrez` (unidades base por
  caja) con `meinh = 'UMV'`. Join por `matnr`.
- `slv_maz_masterdata_sap_pr3.copecac_mara` — maestro de material. `mtart` (tipo; `FERT` = producto
  terminado — cerveza/bebidas), `volum` (volumen unitario, para HL), `normt`.
- `slv_maz_masterdata_sap_pr3.copecac_makt` — descripcion del material. `maktx`, filtrar
  `spras = 'S'` (español).
- `slv_maz_supply_sap_pr3.copecac_mchb` — **stock fisico** (libre utilizacion) por lote,
  material x centro (`werks`). Campo `clabs`. **Estado-vigente.**
- `slv_maz_sales_sap_pr3.copecac_vbbe` — requerimientos SD abiertos (entregas y pedidos).
  `vbtyp='J'` = entregas en curso, `vbtyp='C'` = pedidos de venta abiertos. **CDC, 653M filas —
  SIEMPRE prefiltrar `werks` exacto por performance**, nunca correr sin filtro de centro.
- `slv_maz_supply_sap_pr3.copecac_resb` — reservas abiertas. Normalmente vacio en CDs de producto
  terminado (es de componentes de produccion) — `StockReser` sale 0 en la mayoria de casos.

**Grano:** material (`matnr`) x centro (`werks`).

**Unidades:** unidad base (botella) → cajas (`CA`) via `/marm.umrez`. `HL = cajas * (umrez * volum
/ 100000)`.

**Codigos de centro relevantes para Centro Oriente:** mismo dominio `BK##`/`SJ##` que
`dm_cliente.centro_id` y la tabla de quiebres de stock (ver arriba) — para alcance nacional el
patron es `werks LIKE 'BK%' OR werks LIKE 'SJ%' OR werks LIKE 'AH%'`.

**Pendiente de confirmar (ver tambien advertencias del KPI en `CLAUDE.md`):**
- Set exacto de almacenes (`lgort`) que usa la Z de SAP para "Stock Disp" (~`IQ01`) — el query por
  defecto suma todos los almacenes del centro salvo que se descomente el filtro `lgort`.
- Mapeo `vbtyp` `C`/`J` pendiente de validar contra una foto SAP del mismo instante.

---

## `slv_maz_dataexperience_peru_dm.dm_promocion` — Maestro de promociones

**Que es:** maestro de promociones migrado de Vertica ("Tabla creada de las maestras de
promociones de vertica"). Grano **cliente x promocion x material**. Clusterizada por `mes`,
`desde`, `hasta` — **siempre filtrar por `mes` (formato `yyyymm`)**, es una tabla enorme (ver
volumetria abajo).

**Llave de negocio:** `promocion_id` + `cliente_id` + `material_id`.

**Campos que solemos usar:** `promocion_id`, `cliente_id`, `material_id`, `desde`/`hasta`
(timestamp — vigencia de la promo), `estado`, `bajo`/`alto` (escala: cantidad minima/maxima para
el descuento), `descripcion`, `abreviacion_sap` (llave para cruzar con
`revenue_maestro_etiquetas`), `tipo_mecanica`, `escala`, `periodo_promo`, `estratificacion`.

**Campos de pricing/descuento:** `porcentaje`, `monto`, `ptr`, `ptc`, `mark_up`, `excise`,
`factor_conversion_descuento`, `monto_descripcion_calculado`.

**Campos `*_masivo`:** `subcanal_id_masiva`, `gerencia_id_masiva`, `tipo_vacio_masivo`,
`marca_masivo`, `estratificacion_masivo`, `presentacion_masivo`, `tipo_cliente_masiva` — sugieren
que una promo se puede definir **por cliente especifico o por segmento masivo** (ej. "toda la
gerencia X + marca Y"); no confirmado el mecanismo exacto de expansion segmento→cliente.

**`estado` — validado con datos (mes 202608, cruzado contra `desde`/`hasta` vs. fecha actual):**

| Estado | Filas (mes) | Promos distintas | % vigente hoy | % ya vencido | % futuro |
|---|---|---|---|---|---|
| `R` | 156.1M | 177,481 | 81% | 19% | ~0% |
| `D` | 62.3M | 22,681 | 0% | 100% | ~0% |
| `X` | 13.0M | 69,973 | 0% | 100% | ~0% |
| `N` | 17,854 | 2,644 | 0% | 0% | 0% |

**Confirmado por el usuario (2026-08-27):**
- **`N` = Nuevo** (creada, aun sin activar) — volumen minimo, aparece solo en el mes mas reciente.
- **`R` = Liberado (Activo)** — consistente con el 81% de sus filas dentro del rango
  `desde ≤ hoy ≤ hasta`.
- **`D` = "a borrar"/dar de baja** (cancelada antes de tiempo).
- **`X` = promocion antigua** (vencio/quedo obsoleta). Pista indirecta que sigue siendo util:
  `D` tiene ~2,746 filas/promo en promedio vs. ~186 filas/promo en `X` (3x mas promos distintas
  para menos volumen).

**Metadata:** creada 2025-02-05, owner `javier.armando.diaz@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_dm.dm_combo` — Maestro de combos

**Que es:** maestro de combos (paquetes de 2+ materiales con descuento conjunto). Grano
**cliente x combo x material** (un combo con 2 materiales genera 2 filas por cliente,
diferenciadas por `posicion_material`). A diferencia de `dm_promocion`, ya trae la jerarquia
territorial embebida al estilo `dm_venta` (`direccion`, `gerencia`, `centro`), no hace falta
join a `dm_cliente` para eso.

**Llave de negocio:** `combo_id` + `cliente_id` + `material_id` (+ `posicion_material`).

**Campos que solemos usar:** `combo_id`, `cliente_id`, `material_id`, `desde`/`hasta` (date),
`estado`, `abreviacion_sap` (llave para cruzar con `revenue_maestro_etiquetas`, con
`proyecto = 'combos_promos'`), `descripcion`/`descripcion_corta`, `combinacion` (texto legible del
combo, ej. "1 Guaraná PET 300 + 1 Guaraná Fresa PET 300"), `tipo_combo`, `tipo_mecanica`,
`tope_cliente_mes`, `combos_comprados` (cuantos combos compro ese cliente en el periodo),
`marca`, `brand_pack`, `estratificacion`, `cantidad`/`cantidad_2`, `nombre_material`.

**Campos de pricing/descuento:** `ptr_base_unit`, `ptr_base_unit_promo`, `ptr_base_total_promo`,
`ptr_unit_promo_cp`, `ptr_total_promo_cp`, `ptr_combo_promo_cp`, `porcentaje_sap`,
`descuento_soles_total`.

**Pendiente de confirmar:** valores validos de `estado` en esta tabla (no validado aun contra
fechas como se hizo para `dm_promocion` — no asumir que comparte el mismo dominio `R`/`D`/`X`/`N`
sin verificar).

**Metadata:** creada 2025-02-05, owner `javier.armando.diaz@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_revenue.revenue_maestro_etiquetas` — Etiquetado manual de promos/combos

**Que es:** tabla chica de etiquetado/clasificacion manual ("Created by the file upload UI" —
misma familia de carga manual que `revenue_maestro_sku`: verificar vigencia antes de confiar en
la clasificacion). Mapea el codigo de la promo/combo a un nombre de campana legible.

**Llave de negocio:** `abreviacion_sap` + `proyecto`.

**Campos:** `abreviacion_sap` (llave para cruzar con `dm_promocion.abreviacion_sap` o
`dm_combo.abreviacion_sap`), `proyecto` (`'promos'` o `'combos_promos'` — hay que filtrar el
`proyecto` correcto segun contra cual tabla se este cruzando), `listado` (nombre de la
campana/agrupacion, ej. `"Verano Amazonico"`, `"Regional Lateros"`), `fuente`, `created_at`,
`user_id`.

**Metadata:** creada 2025-02-06, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_salesdata_salesdatadata_adb.pe_promo_adherenciadiaria` — Adherencia a promos/combos + Drops

**Que es:** hecho que mide si el cliente **efectivamente compro** dentro de los terminos de una
promo/combo vigente, cruzado con venta real y con metricas de **Drops** en la misma fila. Es el
punto de union entre `dm_promocion`/`dm_combo` (que define que promos existen y a quien aplican) y
la venta real (`dm_venta`). Grano **cliente x material x promocion/combo x periodo** (mensual, pero
el nombre "diaria" y la presencia de filas duplicadas a nivel periodo sugieren que el detalle real
es diario — `fecha_venta` deberia distinguir esas filas, ver limitacion abajo).

**⚠️ VOLUMEN — la tabla mas grande de todas las mapeadas hasta ahora, mas que `dm_venta`:**
169.6M filas historicas solo para `direccion = 'PE Dir Centro Orient'` (sin filtro de periodo).
**Un solo mes ya son ~4.8M filas** para Centro Oriente. **Nunca correr sin filtro de `periodo` +
al menos otro filtro (cliente, promocion o material)** — el guardrail automatico del skill no
detecta esta tabla como "grande" (solo vigila `dm_venta`), asi que hay que aplicar el criterio
manualmente aca.

**⚠️ `fecha_venta` no sirve para filtrar periodos recientes:** deja de poblarse desde
2025-03-05 (validado con datos), aunque `periodo` (`yyyymm`) sigue actualizado hasta el mes
corriente (202608 al momento de este mapeo). **Usar `periodo`, no `fecha_venta`, para filtros de
tiempo.**

**Llave de negocio:** `cliente_id` + `material_id` + `promocion_id` + `periodo` (grano exacto con
`fecha_venta` aun no confirmado dado el punto anterior).

**Campos que solemos usar:**
- `proyecto` — `'promos'` o `'combos_promos'`: dos universos distintos en la misma tabla (mismo
  campo que en `revenue_maestro_etiquetas`).
- `periodo` (`yyyymm`), `cliente_id`, `material_id`, `promocion_id`, `descripcion`, `combinacion`
  (solo combos), `tipo_mecanica`, `estado` — mismo dominio de codigos que `dm_promocion` para
  `proyecto = 'promos'` (`R`/`X`/`D` observados; ver validacion en `dm_promocion` arriba), para
  `proyecto = 'combos_promos'` se observo `'A'` (hipotesis: Activa — no confirmado).
- `desde`/`hasta` — vigencia de la promo/combo.
- `bajo`/`alto` — escala (cantidad minima/maxima para el descuento).
- `hl`, `gsi`, `dscto`, `cf`, `nr` — venta real de esa fila (mismos nombres/logica que `dm_venta`).
- `promo_venta` — codigo de la promo efectivamente aplicada en la venta (comparar contra
  `promocion_id` para detectar adherencia real vs. solo elegibilidad).
- `flag_venta`, `flag_linea`, `flag_promo` — banderas binarias. **Confirmado por el usuario
  (2026-08-27):** `flag_venta` = el cliente compro el SKU, con o sin promo/descuento aplicado.
  `flag_promo` = el cliente tiene la promo/descuento activo (elegibilidad/vigencia, no
  necesariamente que la haya usado). `flag_linea` — **pendiente, el usuario confirma luego**.
- `centro`, `canal`, `gerencia`, `direccion`, `marca`, `brand_pack`, `listado` (nombre de campana,
  mismo concepto que `revenue_maestro_etiquetas.listado`).
- **Campos de Drops** (conectan esta tabla con el KPI Drops, ver `CLAUDE.md`): `drop_avg_l3m`
  (promedio de drop ultimos 3 meses, cajas), `drop_avg_l3m_rango` (bucket, ej. `"Sin drop"`,
  `"0 a 4"`), `drop_u3m` (drop ultimos 3 meses, valor nominal), `nivel_drop_u3m` (bucket, ej.
  `"c. <3 a 6]"`, `"f. <20 a 50]"`).

**Llaves de join:**
- `promocion_id` → `dm_promocion.promocion_id` (cuando `proyecto = 'promos'`).
- `combo_id`/`promocion_id` → `dm_combo.combo_id` (cuando `proyecto = 'combos_promos'` —
  confirmar nombre exacto del campo de cruce, no verificado aun).
- `abreviacion_sap` → `revenue_maestro_etiquetas.abreviacion_sap` (filtrando por el `proyecto`
  correspondiente) para obtener el `listado`/nombre de campana.

**Metadata:** creada 2025-01-10, formato Delta, tabla EXTERNAL. Catalogo `brewdat_uc_mazana_dev`,
database `slv_maz_salesdata_salesdatadata_adb` (misma database que `pe_portfolio_hm_brand_distribution`
y `pe_promo_adherenciadiaria`).

---

## CD reales por gerencia — Direccion Centro Oriente (validado con el usuario, 2026-08-27)

`dm_cliente.centro` puede traer, para clientes de una gerencia dada, CD que en realidad
pertenecen a otra gerencia o son ruido de reasignaciones — **no asumir la lista de CD de una
gerencia solo mirando el volumen**, confirmarla con el usuario (ver metodologia en
`explorar_centros.sql` del skill `dashboard-gv-volumen`). Listas ya confirmadas:

| Gerencia (`dm_venta.gerencia`) | CD confirmados | Notas |
|---|---|---|
| `PE Ger P4 Pucall Hco` (Pucallpa) | CD Pucallpa, CD Huánuco, CD Tingo María | Se excluyen Iquitos/Yurimaguas/Rimac/sin-CD (volumen marginal, <1%). |
| `PE Ger P4 Tarapoto` (Tarapoto) | CD Tarapoto, CD Yurimaguas, CD Moyobamba, **CD Pucallpa** | **CD Pucallpa aporta ~25K HL/mes** (no marginal, ~47% del volumen "geografico" de Tarapoto) — **100% concentrado en canal `DAs`** (confirmado por query 2026-08-27): son Distribuidores Autorizados que facturan bajo gerencia Tarapoto pero cuya ficha de cliente los tiene abastecidos/asignados desde CD Pucallpa. Se incluye deliberadamente en la lista (decision del usuario) para no perder ese volumen en las vistas filtradas por CD. Quedan afuera CD San Benedicto I (Ate), CD Motupe, CD Chiclayo (~9% del volumen real, si son marginales/de paso). |
| `PE Ger P4 Iquitos` (Iquitos) | CD Iquitos | Unico CD real; el cruce CD Pucallpa+DAs que existe en Tarapoto es aqui puramente ruido (1 fila, 0 HL). |
| `PE Ger P4 Huancay Ch` (Huancayo/Chanchamayo) | CD Huancayo, CD Chanchamayo, CD Satipo, CD Huancavelica | Se excluyen Trujillo/Juliaca/Arequipa/Callao/Chiclayo/Cusco/Cono Sur/Rimac/HUB LURIN MKP (todos volumen residual). |
| `PE Ger P4 DA Jun Puc` | CD Pucallpa, CD San Benedicto I (Ate), CD Satipo, CD Huánuco, CD Huancayo, CD Huancavelica (**todos** los CD que aparecen, sin curar/excluir ninguno) | Confirmado por el usuario: "DA" = Distribuidor Autorizado, 100% canal `DAs` — no es una gerencia geografica como las otras 4, asi que sus CD saltan por varias regiones del pais (incl. uno en Ate/Lima) **como operacion normal, no como ruido**. A diferencia de las gerencias geograficas (donde se curan/excluyen CD marginales), aca se incluyen todos. Agregada al dashboard multi-gerencia el 2026-08-27 (inicialmente se habia dejado afuera del primer run mientras se validaba el patron). |

**Patron general observado:** el canal `DAs` (Distribuidores Autorizados) parece no respetar la
geografia de CD tan limpiamente como los demas canales — los DAs se abastecen del CD mas
grande/cercano sin importar bajo que gerencia comercial facturan. Si aparece un CD "raro" con
volumen no trivial al armar el dashboard de una gerencia nueva, **revisar primero si esta
concentrado en canal DAs** antes de asumir que es puro error de datos (ver metodologia: filtrar
por ese CD + esa gerencia, agrupar por canal).

**Cuidado con nombres de CD compartidos entre gerencias al combinar varias a la vez:** un mismo
nombre de CD puede estar curado-incluido en el `cd_list` de una gerencia y curado-excluido en el
de otra (ej. `CD San Benedicto I (Ate)` esta incluido para DA Jun Puc pero excluido para
Tarapoto). El dashboard multi-gerencia soluciona esto agregando cada gerencia solo contra su
**propio** `cd_list`, nunca contra la lista compartida que se ve en el filtro de Centro del
toolbar (ver `references/reglas_negocio.md` del skill `dashboard-gv-volumen` para el detalle de
un bug real que este descuido causo, ya corregido).

---

## Pendiente de confirmar (no asumir, preguntar al usuario o validar con datos)

- **Confirmado por el usuario (2026-08-28): `direccion_historia`/`gerencia_historia` y
  `direccion_venta`/`gerencia_venta` NO siempre coinciden entre si** (en el unico caso validado
  hasta ahora si coincidieron, pero no es la regla general) — falta un caso concreto de divergencia
  para entender que distingue a cada una y cuando usar una u otra.
- Significado exacto de `flag_linea` en `pe_promo_adherenciadiaria` (`flag_venta` y `flag_promo`
  ya confirmados, ver seccion de esa tabla arriba).
- Mecanismo de expansion de las promos "masivas" (campos `*_masivo` en `dm_promocion`) hacia
  clientes individuales — no confirmado como se traduce un criterio masivo (ej. gerencia+marca) en
  las filas cliente x material que trae la tabla.
- Nombre exacto del campo de cruce `pe_promo_adherenciadiaria` → `dm_combo` cuando
  `proyecto = 'combos_promos'` (no verificado con una consulta real todavia).
