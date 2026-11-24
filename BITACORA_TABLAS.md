# Bitacora de tablas — Databricks (catalogo `brewdat_uc_delta_maz_mazana_dev`)

> **Migracion de workspace (2026-11-24).** Nuevo workspace `adb-1508885077335396.16`, warehouse
> `brewdat-maz-sales-pe-adb-ep01-p` (`8155ae18efb6c905`). El catalogo `brewdat_uc_mazana_dev` que se cita
> abajo ahora es **`brewdat_uc_delta_maz_mazana_dev`** (Delta Share, mismos esquemas y nombres de tabla).
> Las queries de `querys/` y de los skills ya se actualizaron. Cambios de ubicacion:
> - `pe_portfolio_material`: `brewdat_uc_maz_scus_weu_sales_dev_ds` → **`brewdat_uc_maz_dev`**`.gld_maz_sales_portfolio_pe`.
> - `revenue_dev_vw_rev_maestro_drops_brandpack`, `revenue_maestro_etiquetas`, `revenue_dev_aliados`,
>   `rev_lider_aliado_estado_whls`: pasaron de `slv_maz_dataexperience_peru_revenue` a
>   **`brewdat_uc_maz_dev.gld_maz_sales_promo_pe`**.
> - **Sin equivalente encontrado:** `revenue_material_agrupacion`, `das_nombre_homologacion` (queries DAS afectadas).
> - **Quiebres OOS:** la tabla por Volume `dev_onep_fact_critical_items_summary_24h_brand_pack_gold` no existe en el
>   nuevo workspace. La mas cercana es `brewdat_uc_delta_maz_mazana_dev.slv_maz_dataexperience_peru_data.onep_fact_critical_items_summary`,
>   pero con **otro grano** (evento de quiebre a nivel `material_id` + `marca_pack`, con `start_ts`/`end_ts`,
>   `total_out_of_stock_hours`, `hl_so`) y **datos solo hasta 2026-09-12**.
>   **Resuelto (2026-11-24):** las 10 queries OOS de `querys/` se migraron a
>   **`brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack`** (ALZ 4.0, mismo grano, al dia). El `FROM`
>   es una subconsulta que renombra los campos nuevos a los nombres de siempre (`period`→`mes`,
>   `distribution_center_code`→`centro_id`, `brand_pack_name`→`brand_pack`, `active_flag`→`activo_en_cd`,
>   `out_of_stock_hours`→`horas_oos_brand_pack`, `in_stock_hours`→`horas_prendidas_brand_pack`,
>   `available_hours`→`horas_disponibles`, `lost_sales_volume_hl`→`hl_so_brand_pack`, etc.), asi que el resto de
>   esta seccion sigue valiendo. **Validacion vs tabla vieja** (Oct'26 al 19-oct, CO sin domingos, Beer+Rtds):
>   horas OOS **identicas** en las 185 combinaciones CD x brand_pack comunes; la nueva **no trae** Cusqueña
>   Chocolate 355 CAN (10 CDs, 100% OOS, 3,840 h, probablemente descontinuada) ni Cusqueña Trigo 310 NRB en SJ90
>   (0 h) → el uptime sale mas alto que en reportes antiguos; `hl_so` sale ~+5-8% (promedio de preventa
>   recalculado) y viene **nulo en BK43** (Huancavelica). Para comparar con reportes previos, tener presente esta diferencia.
>
> **Modelo ALZ 4.0 (destino oficial).** El equipo de Data envio el diccionario de equivalencias (23-nov-2026):
> `referencias/Diccionario_Datos_ALZ__MLP.html`, exportado a `referencias/Mapeo_ALZ40_Tablas.csv` y
> `referencias/Mapeo_ALZ40_Campos.csv` (tabla y campo actual → nuevo). Las tablas nuevas tienen nombres en ingles
> y estan al dia (validado 24-nov: quiebres al 24-nov, BD con Nov'26). Equivalencias principales (acceso confirmado):
> - `dm_venta` → `brewdat_uc_delta_maz_prod.gld_maz_sales_sell_in.pe_invoice`
> - `dm_cliente` → `brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_customer`
> - `dm_material` → `brewdat_uc_delta_maz_prod.gld_maz_masterdata_sales.pe_product`
> - `revenue_maestro_sku` → `brewdat_uc_maz_prod.slv_maz_masterdata_manual.pe_product_additional_details`
> - `pe_portfolio_hm_brand_distribution` → `brewdat_uc_maz_prod.gld_maz_sales_sell_in.pe_portfolio_brand_distribution` (campos sin mapear en el diccionario)
> - quiebres `..._24h_brand_pack_gold` → `brewdat_uc_maz_prod.gld_maz_sales_bees.pe_stockout_brand_pack` (mismo grano, 18/19 campos mapeados)
> - `dm_preventa_flash_actual_fe` → `brewdat_uc_maz_prod.gld_maz_sales_order.pe_flash_order`; `dm_preventa` → `...gld_maz_sales_order.pe_order`
> - `revenue_material_agrupacion` → `brewdat_uc_maz_prod.gld_maz_masterdata_product.pe_material_group`; `das_nombre_homologacion` → `brewdat_uc_maz_prod.slv_maz_masterdata_manual.pe_name_homologation_das`
> - `revenue_h_pv_planeada` (marcada "Eliminar") → **`brewdat_uc_maz_prod.gld_maz_sales_order.pe_planned_order`**, que es
>   el destino de `revenue_pv_planeada` (mismos campos; lo encontro el usuario, 2026-11-24). Validado 21-23 nov GV Pucallpa:
>   HL, POCs y pedidos identicos; la copia vieja ademas **no traia el plan del 20 ni del 24-nov** (PLAN incompleto).
>   Las 6 queries que la usaban (tracking diario y deep dives de Pucallpa) ya leen la tabla nueva via subconsulta con
>   alias a los nombres antiguos (`planned_delivery_date`→`FechaPlan`, `planned_volume_hl`→`HLPlaneado`,
>   `customer_short_code`→`CodCliente`, `product_short_code`→`SKU`, `order_number`→`NumeroPedido`, etc.).
> **Venta migrada a ALZ 4.0 (2026-11-24):** 126 queries (`querys/` + plantillas del skill `dashboard-gv-volumen`)
> leen `dm_venta`/`dm_cliente`/`dm_material` desde `pe_invoice`/`pe_customer`/`pe_product` via subconsultas con alias a
> los nombres antiguos (guardadas en `referencias/compat_alz40/`). Validacion corriendo cada query en ambos modelos:
> 113 con diferencia <0.5% en sus totales (105 <0.01%). Volumen CO mensual identico Mar'21-Nov'26. Reglas del cruce:
> - `hl` = **`sales_volume_official`** (no `sales_volume`, que desvia algunos SKU p.ej. San Juan 620 / Cristalina).
> - `estratificacion` = `pe_product.product_line` (no `category_name`); `marca` = `pe_product.brand_name`.
> - `mes` = `cast(__partition_column as string)` (particion yyyymm); `dm_cliente.mes` = mes actual Lima (foto vigente).
> - `caja_equivalente` = HL x 13.44086022 (definicion de negocio). **El campo viejo de `dm_venta` usaba otro factor
>   (~13.74-14.06)**: el CE del FACT del tracking baja ~2.3% y ahora es coherente con PLAN/PV.
> - `vendedor` = `pe_customer.bdr_name` (0 diferencias en CO).
> - Diferencias de dato conocidas: `nombre` de cliente cortado a 35 caracteres; `supervisor` generico con otro codigo
>   ("Promotor Generico ..."); 109 clientes CO sin `unidad_negocio_revenue_volumen_meta`; `numero_documento` con ceros
>   a la izquierda y algunos documentos distintos (afecta cruces por DNI/RUC); un SKU pasa de Cervezas a Licores en Dic'25.
> **Se quedan en el modelo viejo (24 queries, ver lista abajo)** porque el nuevo **no tiene historia antes de Mar'21**
> (Resumen/Top/Puente/Drivers/Cubo/Marca_Pack YTD de Pucallpa, Historicos 2020+, Volumen 2021-2022), porque usan
> campos sin equivalente en `pe_invoice` (`vic`, `vlc`, `maco`, `descuento_promocion`, `agrupador` [esta en
> `pe_invoice_class_position`], `dm_cliente.bees`, `vendedor_id`), por el cruce por documento (Recodificacion_Clientes),
> o porque ya fallaban antes (DAS_Sell_In, Plan_Aliados, Promos_Combos, Volumen, Cartera_Flujos_GV_vs_LM).
> Siguen en el modelo viejo tambien `revenue_maestro_sku`, `dm_preventa*`, `dm_hm_cliente`, `dm_das_*`, BD.
> **Nombres nativos (2026-11-24, pedido del usuario):** las 134 queries migradas (venta, cliente, material, quiebres y
> plan) ya no usan subconsultas con alias: leen `pe_invoice`/`pe_customer`/`pe_product`/`pe_stockout_brand_pack`/
> `pe_planned_order` directo con sus campos en ingles; las columnas de salida conservan el nombre antiguo con `as`.
> Cuando hace falta categoria/marca de la venta se agrega `left join pe_product <alias>_p` por `product_short_code`.
> Validado corriendo version con alias vs nativa al mismo tiempo: 125 partes identicas (mismas filas, 0% de diferencia
> en todos los totales); las 9 plantillas del skill solo corren con sus marcadores reemplazados (mismo codigo que sus
> pares en `querys/`, validados). El guardrail de `run_query.sh` ahora tambien vigila `pe_invoice` y acepta
> `__partition_column`/`invoice_date` como filtro de fecha.
>
> Campos clave ejemplo (`dm_venta`→`pe_invoice`): `fecha_venta`→`invoice_date`, `cliente_id`→`sold_to_customer_short_code`,
> `hl`→`sales_volume`, `caja_fisica`→`billed_sales_boxes_quantity`, `nr`→`net_revenue_amount`, `gerencia`→`sales_region_name`,
> `direccion`→`sales_area_name`; **sin mapeo:** `caja_equivalente` (= HL x 13.44086022), `marca`, `brand_pack`, `dscto` (salen de `pe_product`).

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
**Desglose del descuento (validado 2026-11-20, Lima Ene-Oct 2023-2026):** `descuento = descuento_promocion + descuento_canal`
exacto; `descuento_combo` es **parte** de `descuento_promocion`, no un tercer componente. No sumar el combo aparte (infla
el descuento). Ver `querys/Query_Lima_SS_Cubo_Mensual_Precio.sql`. Ojo: en la misma validacion `NR = GSI + EXCISE + DSCTO`
cuadra exacto en 2025-2026, pero en **2023-2024** el NR queda ~S/ 0.3-0.4 MM por año sobre la suma (≈0.03% del NR, casi
todo Multipack, ej. Ene'24 DSD OFF) — irrelevante para ratios, pero no presentar el cuadre como exacto en esos años.
**MACO (validado con datos 2026-11-15, Oct'26 Centro Oriente):** `maco = nr + vic + vlc` cuadra exacto
(`vic`/`vlc` vienen en negativo), sin nulos. Grano = el de `dm_venta` (linea de documento), asi que se
abre por cualquier dimension (cliente, material/brandpack, gerencia, CD, canal, dia). Moneda: soles
(misma que `nr`); los reportes globales (1YP) hablan de MACO en USD/HL, no comparar sin convertir.
MACO/HL = `SUM(maco)/SUM(hl)` (no promediar ratios). Referencia Oct'26 Beer+Rtds CO: ~S/ 488/HL.

**ALERTA `marca` (detectada 2026-11-04, GV Pucallpa):** `dm_venta.marca` viene NULL en el 100% de las filas de 2020-01 a 2023-12 (poblada desde 2024-01; validado en toda Centro Oriente). Usar `dm_material.marca` (join por `material_id`) en series multi-anio. Ojo: el filtro `NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')` evalua NULL con marca nula y **elimina TODA el Agua** de esos anios; escribir `COALESCE(m.marca,'') = 'San Mateo'`. Afecta Nabs 2020-2023 (no Beer+Rtds); `Query_CentroOriente_Historico_*` ya corregidas. Desde 2024 ambos filtros dan lo mismo en Agua, asi que las queries que arrancan en 2025 no cambian de resultado, pero las plantillas parametrizadas del skill `dashboard-gv-volumen` siguen con `v.marca`: no usarlas con `MES_DESDE` anterior a 2024. Ver `querys/Query_Pucallpa_Cubo_Mensual.sql`.
**Agrupacion de marcas para reportes (usuario, 2026-11-10):** todas las variantes `Mikes H *` (sabores, mayus/minus) = **Mike's**; toda la familia `Cusqueña*` (Trigo, Malta, Negra, Cero Trigo, Quinua, etc.) = **Cusqueña**; `Corona Extra/Coronita/Cero/Tropical` = Corona; `Pilsen Fresh` + `Pilsen Callao Fresh` = Pilsen Fresh; `golden` = Golden (Licores); **Golden 6XX** = `620 RB` (hasta Jul'25) + `650 RB` (desde Abr'25), cambio de formato que se compara junto.

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

**Ojo con `centro_id` de los DAs (validado 2026-11-17):** el CD de un DA en `dm_cliente` es el que lo
factura, no el de su zona. Ejemplo: en GV Tarapoto, `SJ97` (CD Pucallpa) concentra 45% del volumen
Beer+Rtds YTD Oct'26 (297.6 mil HL), pero son solo **5 clientes canal `DAs`** de Jaén y San Ignacio
(Cajamarca) y Utcubamba y Chachapoyas (Amazonas), todos con supervisor Raúl Delgado. Al cortar por CD,
separar DAs de DSD; si no, los CD de reparto quedan subrepresentados.

**Mapeo `unidad_negocio_revenue_volumen_meta` → canales PPM (validado con datos, gerencia
Pucallpa):** este es el campo al que el usuario se refiere informalmente como "unidad_negocio_meta"
para su clasificacion de canales. Valores observados y su equivalencia con la nomenclatura del rol
(ver CLAUDE.md → "Rol"): `DSD OFF`, `DSD ON`, `Mayoristas` (= WHL), `Eventos` (= EVE),
`Key Accounts` (= KA), `DAs` (= DAS), y un residual `High End` (no forma parte de los 6 canales
que maneja el usuario, volumen marginal). **No confundir con `dm_venta.unidad_negocio_venta`**
(u `unidad_negocio`/`unidad_negocio_revenue`), que es un campo distinto con otro dominio de valores
(`Off Premise`, `On Premise`, `Mayoristas y Eventos`, `Key Accounts`, `Consumidor`, `DAs`) — no sirve
para este mapeo de canal.
**Convencion de reporte (usuario, 2026-11-10):** `High End` se suma dentro de **DSD ON** al
mostrar canales (queda en 6 canales: DAs, DSD OFF, Mayoristas, Eventos, DSD ON, KA). Campo de canal
confirmado por el usuario (2026-11-10): `dm_cliente.unidad_negocio_revenue_volumen_meta` (vigente).
**Apertura por CD en GV Iquitos y GV Tarapoto (usuario, 2026-11-10):** separar el canal DAs en lineas
propias `DAS - CD <nombre>` (ej. `DAS - CD Iquitos`, `DAS - CD Pucallpa`); el resto de canales queda como
`CD <nombre>`. Las demas GV se abren solo por CD. Query: `querys/Query_CentroOriente_Volumen_BeerRtds_Gerencia_CD_DAS_Mensual_2023_2026.sql`.

**POCs compradores (2026-11-10):** cliente con `SUM(hl) > 0` en el periodo (Beer+Rtds,
`indicadores_comerciales = 1`), agregando primero a grano cliente-periodo en `dm_venta`. Gerencia y canal salen de
`dm_cliente` (vigentes), por eso los conteos son aditivos entre GV y canal. Mensual:
`querys/Query_CentroOriente_POCs_BeerRtds_Gerencia_Canal_Mensual_2023_2026.sql`; distintos en el YTD Ene-Oct:
`querys/Query_CentroOriente_POCs_BeerRtds_YTD_Gerencia_Canal_2023_2026.sql`. En DAs, KA y Eventos el "POC" es un
codigo de distribuidor o cuenta: su variacion refleja consolidacion de codigos, no perdida de mercado. No es el KPI
Cobertura por categoria (sigue pendiente de mapear).

**Otros campos utiles para segmentacion/analisis:**
- Jerarquia comercial **actual** del cliente: `direccion`, `director`, `gerencia`, `gerente`,
  `subgerencia`, `supervisor`, `vendedor`, `zona_pem`, `zona_comisional`, `zona_venta`.
- Canal: `canal`, `subcanal`, `subcanal_local`, `subcanal_regional`.
- Segmentacion: `bees_segmento`, `obppc_stage`, `obppc_cluster`, `arquetipo_prioridad_1/2`.
- Ubicacion: `departamento`, `provincia`, `distrito`, `direccion_geo`, `localidad`.
- Estado/vigencia: `estado`, `fecha_alta`, `fecha_baja`, `indicadores_comerciales`.
- Comercial/credito: `linea_credito`, `cxc_liq_perc`, `cxc_envase`, `puntos`, `club_b`.
- KKAA (cuentas clave): `kkaa_kam`, `kkaa_cadena`, `kkaa_manager`, `kkaa_coordinador`.

**Nota clave (resuelto 2026-09-04, ver CLAUDE.md → "Alcance tipico"):** la jerarquia territorial
de este maestro (actual) puede diferir de la que trae `dm_venta` al momento historico de la
venta. **Regla vigente: usar `dm_cliente` (esta tabla) como fuente de gerencia/supervisor/
direccion/nombre para reportes, unida por `cliente_id`** — no los campos homonimos de
`dm_venta`. Motivo: un cliente reasignado de gerencia a mitad de año (caso real: **Ucayali
Beer**, `PE Ger P4 Huancay Ch` → `PE Ger P4 DA Jun Puc` en abril 2026) queda partido entre dos
gerencias en `dm_venta.gerencia` segun el mes de la venta (esos cambios de cliente individual NO
se reescriben retroactivamente, a diferencia de la reestructuracion de GV de inicios de 2026),
generando saltos artificiales en series YoY. `dm_cliente` al ser una foto unica/vigente atribuye
todo el historico del cliente a su gerencia actual de forma consistente.

**`vendedor` vacio (confirmado 2026-11-04):** en la GV Pucallpa `dm_cliente.vendedor`, `vendedor_id` y `vendedor_nombre` no traen valor util en CD Pucallpa (DSD OFF, 2025-2026); `zona_venta` y `bees_segmento` tambien vienen vacios; el corte de jerarquia llega hasta `supervisor`.

**`estado` y `fecha_baja` (validado con datos 2026-11-05, GV Pucallpa):** `estado` es INT: `1` = activo, `0` = inactivo. Inferido por compra real, no por definicion oficial: de 6,127 clientes con compra en `dm_venta` en oct'26, 6,121 tienen `estado = 1` y solo 6 tienen `estado = 0`. `fecha_baja` no sirve para identificar bajas: trae `1900-01-01` en todos los clientes de la GV, activos o no. `estado = 1` no implica compra reciente: solo ~50% de los activos compro en oct'26.

**`fecha_alta` = fecha de creacion del codigo (validado con datos 2026-11-11, Centro Oriente):** viene
llena en todos los clientes, sin nulos ni fechas dummy; va de `2009-04-21` (arranque del sistema, los
codigos mas antiguos quedan con esa fecha) a ayer. Cuadra con la primera aparicion del codigo en
`dm_hm_cliente`: de 25,431 codigos con alta entre may'23 y oct'26, el 97.5% aparece por primera vez
en el mes de su `fecha_alta`, el 2.4% un mes antes (altas del dia 1-2 del mes siguiente que entraron
en la foto anterior) y el 0.1% un mes despues. Usarla para identificar clientes nuevos por mes.

**Metadata:** creada 2025-02-05, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

---

## `slv_maz_dataexperience_peru_dm.dm_hm_cliente` — Historico mensual del maestro de cliente

**Que es (validado con `DESCRIBE TABLE EXTENDED` y datos, 2026-11-11):** fotos mensuales de
`dm_cliente`, una fila por cliente por `mes` (string `YYYYMM`). Cubre `202210` a `202610`; no trae el
mes en curso (`dm_cliente.mes` = `202611` al 11.11.26). Unas 1.1-1.3M filas por mes. Sin particion
declarada, formato Delta, creada 2025-02-06, mismo owner que `dm_cliente`.

**Esquema:** 112 columnas, mismas que `dm_cliente` salvo: solo aqui `fecha_carga` (null desde
`202403`); solo en `dm_cliente` `cliente_id_central`, `club_b`, `kkaa_cadena_2`, `localidad`,
`localidad_id`, `subcanal_regional`, `supervisor_desarrollo_id`, `supervisor_portfolio`,
`via_pago_general`, `via_pago_sociedad`, `zona_transporte`, `zona_transporte_id`.

**Ojo al usarla:**
- **No se reescribe con la reestructuracion de GV.** `direccion = 'PE Dir Centro Orient'` existe solo
  desde `202602`. Hasta `202601` la region estaba en `PE Dir Oriente` (~119K clientes) y la GV Huancayo
  en `PE Dir Centro Sur`. Filtrar por la direccion actual devuelve 0 filas antes de feb'26.
- **Sin filtro de `mes` apila todos los meses**: un cliente aparece una vez por mes.
- **Duplicados en `202602`:** 32 clientes con 2-4 filas, algunos con 2 direcciones o gerencias.
  Deduplicar antes de contar ese mes.
- **Quiebre en `202505`:** pasa de 1.31M a 1.14M filas (depuracion del maestro), no es perdida real.
- Cuadra con `dm_cliente`: Centro Oriente `202610` = 178,324 filas vs 178,360 en `dm_cliente`.
- **La foto de cada mes es de cierre, tomada el dia 1-2 del mes siguiente.** Por eso algunas fotos
  incluyen codigos creados el dia 1-2 del mes siguiente: `202609` trae 572 codigos de Centro Oriente con
  alta del 01.10.26, `202403` trae 28 y `202306` trae 7. Las demas fotos (incluida `202512`) no traen
  altas del mes siguiente. Para un corte exacto al ultimo dia, filtrar ademas `fecha_alta <= ultimo dia del mes`.

- **`202210` a `202303` son la misma foto** (cargada el 05.04.23, misma cantidad de clientes por GV). Recien
  desde `202304` hay fotos mensuales reales; no leer movimiento en ene-mar'23.
- **GV Pucallpa historica:** hasta `202601` = `PE Ger P4 Pucallpa` (CD Pucallpa) + `PE Ger P4 Huánuc Tma`
  (CD Huanuco y Tingo Maria); desde `202602` = `PE Ger P4 Pucall Hco`. El nombre del supervisor cambia de
  formato en el tiempo (ej. "Trujillo Rubin, Cesar Jose" → "JOSE TRUJILLO"): agrupar por `supervisor_id`.
- **Carga masiva oct'26 (GV Pucallpa):** ~1,380 codigos con alta 01.10.26, subcanal Particular, asignados
  al supervisor "Promotor generico PEDLF6" (`supervisor_id` 8X); en la foto `202609` aparecen con los
  supervisores reales. Solo 3 compraron al 11.11.26. Separarlos al medir crecimiento de cartera.
- Queries de cartera mensual y flujos vs LM: `querys/Query_Pucallpa_Cartera_Mensual_CD_Supervisor.sql`,
  `querys/Query_Pucallpa_Cartera_Flujos_vs_LM.sql`.
- **Centro Oriente historico (confirmado por el usuario 2026-11-11):** hasta `202601` se arma con las gerencias
  de entonces mapeadas a las 5 GV actuales: Huancay Ch = `PE Ger P3 Huancayo` (ex `PE Dir Centro Sur`) +
  `PE Ger P4 Chanchamay`; Pucall Hco = `PE Ger P4 Pucallpa` + `PE Ger P4 Huánuc Tma`; Tarapoto e Iquitos con
  su nombre; DA Jun Puc existe desde `202602`. Validado con cruce cliente a cliente ene'26 → feb'26.
- **Excluir clientes de prueba/Marketplace a nivel cliente (usuario, 2026-11-11):** en feb'26 entraron a
  Huancay Ch ~1,350 clientes MTKP Gloria desde `PE Ger P1 Lima Centr`, con supervisor "SUPERVISOR PRUEBA" y
  CDs de todo el pais. En nov'26 parte de ellos se renombro a "Promotor generico PEDLF6", asi que filtrar por
  nombre de supervisor del mes no alcanza: excluir en todo el historico a cualquier `cliente_id` que alguna vez
  tuvo `subcanal LIKE 'MTKP%'` o supervisor `%PRUEBA%`.
- **Promotores genericos en Centro Oriente (nov'26):** ~8 mil clientes (17.5% de la cartera), sobre todo altas
  masivas set-oct'26 en Pucall Hco, Iquitos y Tarapoto, y ~2.6 mil clientes existentes reasignados en jun'26 en
  Huancay Ch. Solo 2.7% compro ago-nov'26 vs 73.5% de clientes con supervisor. Sin ellos la cartera cae -1.4% vs LY.
- **`frecuencia_visita` (validado 2026-11-11, Centro Oriente):** valores `Semanal`, `Quincenal` (con `q_visita`
  Q1/Q2 = quincena), `Bisemanal` (2 veces por semana), `Mensual`, `OTROS` (aparece desde jun'26) y vacio = sin
  visita asignada (todos los promotores genericos y las cuentas grandes: DAs, mayoristas, KA). Para comparar
  intensidad se usa visitas/mes: Bisemanal 8, Semanal 4, Quincenal 2, Mensual 1, vacio 0. Analizar solo DSD
  (OFF+ON) sin genericos. `frecuencia_b2p` es otro campo (no usado, significado sin confirmar).
- **Recodificacion de cuentas grandes:** el cruce por `numero_documento` no detecta recodificaciones porque el
  grupo cambia de RUC (ej. Iquitos: "Inversiones Bonanza del Oriente" dejo de comprar en 2026 y entro
  "Grupo Bonanza SAC" con 3 codigos nuevos, ~34 vs ~37 mil HL). Revisar a mano los top clientes perdidos/nuevos.
- Venta por cohorte y frecuencia (YTD Ene-Oct): `querys/Query_CentroOriente_Venta_Cartera_Cohorte_YTD.sql`,
  `querys/Query_CentroOriente_Venta_Mensual_Cohorte_Alta.sql`, `querys/Query_CentroOriente_Frecuencia_Visita_Mensual_Venta.sql`,
  `querys/Query_CentroOriente_Cambio_Frecuencia_Visita_vs_Venta.sql`, `querys/Query_CentroOriente_Top_Clientes_Perdidos_Nuevos_YTD.sql`,
  `querys/Query_CentroOriente_Recodificacion_Clientes_YTD.sql`.
- Queries regionales: `querys/Query_CentroOriente_Cartera_Mensual_GV_CD_Supervisor.sql`,
  `querys/Query_CentroOriente_Cartera_Flujos_GV_vs_LM.sql`, `querys/Query_CentroOriente_Compra_Genericos_vs_Supervisor.sql`.

**Uso:** solo para ver como estaba la cartera en un mes pasado. Para atribuir gerencia en reportes
sigue la regla de `dm_cliente` (foto vigente).

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

**Formato del valor de `pack`:** `<capacidad en ml><tipo de envase>`, ej. `355 CAN`, `473 CAN`,
`269 CAN` (latas), `630 RB`/`620 RB`/`650 RB`/`305 RB`/`1000 RB` (retornable, botella de vidrio
retornable), `330 NRB`/`310 NRB`/`305 NRB`/`355 NRB`/`210 NRB` (non-returnable, botella
descartable). **Para filtrar solo LATAS: `r.pack LIKE '%CAN%'`** (validado 2026-09-10, Cervezas
Centro Oriente Jun-Ago 2026: 3 valores de `pack` con `CAN`, todos exclusivamente latas — sin falsos
positivos). Para "Brand Pack" (marca + formato) a nivel SKU-agregado, usar
`CONCAT(marca, ' ', pack)` sobre `dm_venta.marca` + `revenue_maestro_sku.pack` (distinto del
`brand_pack` de `dev_onep_fact_critical_items_summary_24h_brand_pack_gold`, que ya viene
pre-armado con otra convención — ver esa tabla más abajo).

**Metadata:** creada 2025-02-05, owner `gen_maz_pe_win053@gmodelo.com.mx`, formato Delta.

**Campo `` `Agrupador (Tipo 2.0)` ``:** explorado 2026-09-03 (Centro Oriente, Beer+Rtds, YTD
Ene-Ago 2026). Valores observados: `Core 6xx`, `CSQ 6xx`, `Latas`, `SS x 24`, `RTDs`, `Corona
Extra`, `Otros`, `Litro`, `SS x 6`, `GBs`, `Cero` (11 valores, cruzado tambien con
`` `Agrupador (Tipo)` `` mas fino y `kpi_premium` Si/No). **No coincide 1:1 con la
microsegmentacion de categorias que usa el equipo de RGM central en sus presentaciones a
Direccion** (ej. una presentacion de referencia de H1'26 mostraba categorias `Core 6XX`, `Latas
Core`, `RTDs`, `P.Fresh`, `Otros`, `Nolo`, `F.Fish`, `Premium`, `Affordable` — parecido pero no
igual, sin un mapeo limpio 1:1 encontrado todavia). Si se pide reproducir esa segmentacion exacta
en el futuro, no asumir que `` `Agrupador (Tipo 2.0)` `` alcanza solo — confirmar con el usuario
la fuente/logica exacta (podria ser una tabla o regla que RGM central arma aparte, no derivable
solo de `revenue_maestro_sku`). Mientras tanto, los analisis de "categoria" en este proyecto usan
la taxonomia propia ya validada: Beer/Rtds/Nabs por `estratificacion` (ver CLAUDE.md).
**`SS x 24` (DSD ON, 2026-11-11):** en Centro Oriente son 3 SKUs retornables en caja de 24: Pilsen Callao 305 RB, Cristal 305 RB y Cusqueña 310 RB (Golden 305 RB solo tuvo 3 HL en 2023). `ms_ss` = 'SS' agrupa ademas latas, Corona, RTDs, GBs, SS x 6 y Cero. Queries: `querys/Query_CentroOriente_DSDON_*.sql`. **Ojo con `nr` de 2023:** en el agregado mensual DSD ON da NR/HL ~445 vs ~626-675 en 2024-2026; no comparar precio NR/HL de 2023 sin revisar la fuente.

---

## `slv_maz_salesdata_salesdatadata_adb.pe_portfolio_hm_brand_distribution` — Hecho de Brand Distribution

**Que es:** tabla pre-calculada del KPI **Brand Distribution** (ver definicion en `CLAUDE.md` →
"KPIs propios de Backus") a grano cliente-material-mes. Trae el flag `flag_brand_distro` (int):
sumarlo agrupado por gerencia/marca/mes/etc. da directamente la metrica — validado corriendo la
consulta con un mes de datos (`sum(flag_brand_distro)` da valores del orden de cientos por
combinacion marca/gerencia, consistente con la definicion de la capacitacion). Catalogo:
`brewdat_uc_mazana_dev` (mismo catalogo que `dm_venta`, database distinta).

**Particionado:** por `mes`.

**Campos:** `mes`, `direccion`, `gerencia`, `fecha_venta` (date), `tipo` (`SELLIN` o `SELLOUT`,
confirmado 2026-08-31 corriendo `group by tipo`), `cliente_id`, `material_id`, `hl` (decimal),
`flag_brand_distro` (int), `marca_tarea`, `marca_offer`, `flag_comparable` (int).

**SELLIN vs SELLOUT:** `SELLIN` = lo que Backus vende al POC (universo mas grande, ~2x SELLOUT en
volumen de Brand Distribution). `SELLOUT` = lo que el POC vende al consumidor final (universo mas
chico, probablemente clientes con dato de venta al consumidor disponible, ej. moderno/KKAA) —
pendiente confirmar el criterio exacto de que clientes reportan SELLOUT. Ambos usan el mismo
`flag_brand_distro`, filtrar por `tipo` segun cual de las dos vistas se necesite.

**LIMITACION ESTRUCTURAL confirmada (2026-09-02): SELLOUT no se puede atribuir a CD.** El
`cliente_id` de las filas `tipo = 'SELLOUT'` **no existe en absoluto en `dm_cliente`** (el join
`dm_cliente c on c.cliente_id = v.cliente_id` da `c.centro_id IS NULL` para el 100% de las filas
SELLOUT, validado con `group by tipo, centro_id` sobre un mes completo — no es que caigan en un CD
distinto, simplemente no cruzan). La tabla tampoco tiene un campo de CD propio (`DESCRIBE` solo
trae `mes, direccion, gerencia, fecha_venta, tipo, cliente_id, material_id, hl,
flag_brand_distro, marca_tarea, marca_offer, flag_comparable`). Los `cliente_id` de SELLOUT
probablemente vienen de otra fuente (ej. reporte de venta al consumidor de terceros/moderno) que
nunca se mapeo al maestro de clientes de Backus.
**Impacto:** cualquier corte por CD de esta tabla (join a `dm_cliente` para traer `centro_id`)
**excluye 100% del SELLOUT silenciosamente** — para Iquitos y Tarapoto (las unicas gerencias con
SELLOUT real) el "total oficial por CD" que usa la regla SELLIN+SELLOUT en realidad solo trae
SELLIN cuando se filtra por CD, aunque la formula/etiqueta diga que incluye ambos. Confirmado que
esto afectaba el artifact "Evolución de Brand Distribution" (vista por CD) — corregido el label
2026-09-02, pendiente evaluar si se puede conseguir el CD real de SELLOUT desde otra fuente.
**Tambien impide un corte por CLIENTE de SELLOUT** (confirmado 2026-09-04 para `PE Ger P4 DA
Jun Puc`: 8,414 `cliente_id` distintos en SELLOUT, **0 matchean** en `dm_cliente` sobre un mes
completo) — sin nombre ni identidad de cliente disponible. Es especialmente relevante para DA
Jun Puc porque su Brand Distribution oficial es **100% SELLOUT** (ver regla de canal en
CLAUDE.md): no existe forma de desglosar el Total oficial de esta gerencia por cliente. El
segmento "Brand Distribution" del dashboard `da_jun_puc_dashboard.html` resuelve esto mostrando
el detalle por cliente con **SELLIN** en su lugar (17-25 codigos → 13 clientes reales
agrupando por nombre, mismos clientes que "Por Cliente" en Volumen) — dejando explícito que es
una fuente distinta y no oficial (el universo SELLIN completo de DA Jun Puc es ~365-y pico de
`flag_brand_distro`/mes vs. ~30-37K del Total SELLOUT, no comparable ni sumable).

**Resuelto (2026-09-08): sí existe una fuente con identidad de cliente para el SELLOUT de DA Jun
Puc — no es esta tabla, es `dm_das_venta`/`dm_das_cliente` (ver seccion dedicada mas abajo).**
Un query nuevo del usuario (`querys/Query_Brand_Distro_DAS.sql`) recalcula el flag de Brand
Distribution desde el detalle transaccional de esa tabla, agregado a nivel **distribuidor**
(`dm_das_cliente.sociedad`) — validado sumando los distribuidores contra el Total oficial de esta
tabla (`pe_portfolio_hm_brand_distribution`, SELLOUT, DA Jun Puc): cuadra exacto en abr/may/jun'26
y con diff <0.15% en jul/ago'26. El dashboard `da_jun_puc_dashboard.html` ya usa esta fuente para
su segmento "Brand Distribution" (reemplazando el parche SELLIN anterior).

**BD MTD (validado 2026-10-19):** cada fila con `flag_brand_distro = 1` cae en la `fecha_venta` de
la **primera compra del mes** de esa combinacion cliente-material (la distribucion diaria del flag
decrece a lo largo del mes, con casi nada en domingos). Por eso filtrar `fecha_venta` entre el dia 1
y el dia -1 da directamente el Brand Distribution MTD comparable vs el mismo rango LY. Ver
`querys/Query_Brand_Distribution_MTD_vs_LY_Detalle.sql`.

**Carga detenida (detectado 2026-11-17):** la tabla llega solo hasta `fecha_venta` 22.10.26; no hay
`mes = '202611'`. Para BD de meses sin carga, recalcular desde la venta: 1 punto por cliente-material
con `sum(caja_fisica) > 0` en la ventana. SELLIN = `dm_venta` (`indicadores_comerciales = 1`) +
`dm_cliente`; SELLOUT = `dm_das_venta` + `dm_das_cliente`. Validado en Nov 1-16 2025 vs esta tabla:
SELLIN da +1% a +1.8% por GV (sesgo parejo, sirve para comparar vs LY con el mismo metodo); SELLOUT
cuadra exacto. `dm_das_venta` llega con ~2-3 dias de rezago vs `dm_venta`: cortar SELLOUT en su
ultima fecha cargada en ambos años. Query: `querys/Query_Brand_Distribution_Nov_MTD_vs_LY_Supervisor_BrandPack.sql`.

**Llaves de join:** `material_id` → `pe_portfolio_material.material_id` (ver tabla siguiente —
catalogo distinto).

**Nota:** no tiene columna `indicadores_comerciales` (esa es propia de `dm_venta`/`dm_cliente`) —
no asumir ese filtro aca.

**ALERTA calidad de dato (detectada 2026-08-31):** la columna `hl` para `tipo = 'SELLOUT'` salta
~10x a partir de `mes = '202503'` (ej. Direccion Centro Oriente: ~50K HL/mes hasta feb'25, salta a
400K-600K HL/mes desde mar'25 en adelante) mientras `flag_brand_distro` se mantiene estable/
consistente en toda la serie. Sospecha de cambio de unidad o de fuente en el calculo de `hl` para
SELLOUT a partir de esa fecha. **No usar `sum(hl)` de SELLOUT para analisis de volumen sin
investigar esto primero** — `flag_brand_distro` (la metrica de Brand Distribution en si) no parece
afectado.

**Metadata:** creada 2024-12-10, owner `lizbeth.leon@gmodelo.com.mx`, formato Delta, tabla EXTERNAL.

---

## `slv_maz_dataexperience_peru_dm.dm_das_venta` / `dm_das_cliente` — Venta y maestro de cliente del canal DAs

**Que son:** par hecho/maestro **especifico del canal DAs** (Distribuidor Autorizado), separado de
`dm_venta`/`dm_cliente`. Descubierto/documentado 2026-09-08 a partir de `querys/Query_Brand_
Distro_DAS.sql` y `querys/Query_DAS_Sell_Out.sql` (ambos ya existentes en el proyecto). Mismo
catalogo que `dm_venta` (`brewdat_uc_mazana_dev`), misma database `slv_maz_dataexperience_peru_dm`.

**Por que existen aparte:** para gerencias de canal DAs (ej. `PE Ger P4 DA Jun Puc`), Backus no le
vende directo al punto de venta (POC) final — le vende a un **distribuidor** (nuestro cliente
directo, ej. "Dismar Cinco", "P & A Logistic S.A.C. - Huancayo"), y ese distribuidor revende a su
propia red de POCs. `dm_das_venta`/`dm_das_cliente` reportan esa venta del **distribuidor a sus
propios POCs** (el SELLOUT real de ese canal) — de ahi que sea la fuente detras del `tipo =
'SELLOUT'` de `pe_portfolio_hm_brand_distribution` para estas gerencias.

**Campos usados:** `dm_das_venta`: `mes`, `fecha_venta`, `direccion`, `gerencia`, `cliente_id`,
`material_id`, `caja_fisica`, `hl`, `indicadores_comerciales`. `dm_das_cliente`: `cliente_id`,
`sociedad` (razon social — **este es el nombre de nuestro distribuidor real**, ej. "Dismar Cinco
Sociedad De Responsabilidad Limitada Huánuco"), `direccion`, `gerencia`, `zona_comisional`
(codigo de ruta/zona del POC, ej. "PE05027").

**GRANO CRITICO — `cliente_id` es el POC final, NO el distribuidor** (confirmado 2026-09-08,
`PE Ger P4 DA Jun Puc`): un mismo distribuidor (`sociedad`) tiene **miles** de `cliente_id`
distintos debajo — ej. "P & A Logistic S.A.C. - Huancayo" con 7,746 codigos, "Dismar Cinco" con
4,722. **Nunca agregar/mostrar a nivel `cliente_id` sin agrupar por `sociedad` primero** — el
grano fino es el punto de venta que el distribuidor abastece ("el cliente de nuestro cliente"),
no algo que interese reportar en un dashboard de gerencia/distribuidor. Para Brand Distribution
u otro KPI de venta de este canal, **agregar siempre por `sociedad`** (o, si hace falta mas
detalle geografico, por `zona_comisional`, nunca por `cliente_id` suelto).
**Impacto real:** una primera version de `Query_Brand_Distro_DAS.sql` que corria las window
functions de Brand Distribution sin filtrar por distribuidor primero, y solo filtraba gerencia al
final, escaneo el universo DAS completo a grano POC y exedio el limite de resultado inline de
Databricks (26MB) — hubo que reescribir para filtrar `cliente_id` temprano (via subquery a
`dm_das_cliente` por gerencia) y agregar el resultado final solo a nivel `sociedad`.

**`gerencia` en `dm_das_cliente` es la jerarquia vigente del maestro de cliente** (mismo criterio
que `dm_cliente.gerencia`, ver regla vigente en `CLAUDE.md` sobre usar el maestro de cliente y no
el hecho de venta para gerencia) — filtrar por `dm_das_cliente.gerencia`, no por
`dm_das_venta.gerencia`, para evitar el mismo problema de reasignaciones de cliente ya documentado
para `dm_venta`/`dm_cliente`.

**7 distribuidores confirmados en `PE Ger P4 DA Jun Puc`** (2026-09-08, por volumen de Brand
Distribution SELLOUT descendente): P & A Logistic S.A.C. - Huancayo, Dismar Cinco Sociedad De
Responsabilidad Limitada Huánuco, Transblanco J & M S.R.L, Inversiones Globales Olarte S.A.C.,
Jhotogo Inversiones S.A.C., Representaciones e Inversiones Selva Oriente EIRL, Ucayali Beer
(marginal, solo desde ago'26 — ver caso de reasignacion de gerencia de este mismo cliente en
`CLAUDE.md`). Coincide en su mayoria con los distribuidores ya identificados via SELLIN en
`dm_venta`/`dm_cliente` para "Por Cliente" en el dashboard de Volumen, aunque la razon social
exacta puede variar levemente entre ambas fuentes (ej. "Inv. Globales Olarte" en `dm_cliente` vs.
"Inversiones Globales Olarte S.A.C." en `dm_das_cliente`).

**Otras notas de `Query_Brand_Distro_DAS.sql`:** el flag de Brand Distribution se recalcula desde
cero (no viene precalculado como en `pe_portfolio_hm_brand_distribution`) con una logica de
"primera venta neta positiva del mes por cliente-material" (acumulado que contempla notas de
credito devolviendo el neto a cero y luego reactivandose). Usa `brand_category` de
`pe_portfolio_material` (`'Megabrand'`, `'RTDs'`, `'Beer NO Megabrand'`) como filtro de alcance —
taxonomia distinta a `estratificacion`, presumiblemente equivalente a "Beer+Rtds sin Marketplace/
Nabs" pero no formalmente reconciliada campo a campo contra `estratificacion IN ('Cervezas',
'Licores','Ready To Drink')` — si se necesita ese detalle, confirmar antes de asumir 1:1.

**Para desglosar `dm_das_venta` por categoria (Beer/Rtds/Nabs), usar
`pe_portfolio_material.estratificacion` (join por `material_id`), NO
`revenue_material_agrupacion.grupo_id`** (confirmado 2026-09-08, construyendo "Por Cliente -
Sell Out" en `da_jun_puc_dashboard.html`). `revenue_material_agrupacion` tiene **grano material x
grupo** — un mismo `material_id` puede tener hasta 4 `grupo_id` distintos a la vez dentro del
mismo mes (tags que se solapan, ej. un RTD esta simultaneamente en `'01'` Beer+Licores+RTD,
`'53'` RTD y `'90'` SS+RTD) — filtrar con `grupo_id IN (...)` sobre varios tags a la vez
**duplica volumen** por el join. Para un total combinado sin desglosar existe `grupo_id = '02'`
("Beer + Licores + RTD + NABs", una sola fila por material, sin ese riesgo), pero no sirve para
separar por categoria individual. `estratificacion` en cambio es un valor unico por material
(mismo campo que se usa en el resto del proyecto), cobertura de join validada 100% (0 HL sin
mapear) para el alcance DA Jun Puc 2025-2026. Query de referencia:
`querys/Query_DAJunPuc_Cliente_SellOut_Mensual.sql`.

**Metadata (DESCRIBE, 2026-11-11):** `dm_das_venta` tiene 43 columnas, entre ellas `razon_social`
(= **distribuidor**, ~10 en CO) e `id_sucursal` (sucursal del distribuidor, ~27 en CO). Ambas son un
grano seguro para reportar, a diferencia de `cliente_id` (POC final, ~16.6K/mes en CO). Tambien trae
`canal_cliente`/`subcanal_cliente` del POC, `estratificacion`, `valor_neto`/`descuento`/`monto_soles`
y los volumenes `caja_fisica`/`caja_equivalente`/`hl` (decimal(38,30)).
- **Historia:** desde Ene'23. En CO aparecen **3 GV** con DAS (segun `dm_das_cliente.gerencia`):
  DA Jun Puc, **Tarapoto** (Represent y Dist. del Norte + Dismar Cinco) e **Iquitos** (Inversiones
  Bonanza del Oriente, **solo desde Jun'25**: su crecimiento YoY es incremental, no organico).
- **`v.estratificacion` sirve para Beer+Rtds** (`IN ('Cervezas','Licores','Ready To Drink')`). Trae
  ademas valores de Marketplace (`Licor MP`, `Sodas Marketplace`, `Comestibles`, etc.) que este
  filtro ya excluye. Los nombres cambian de mayusculas entre años (`Licor MP`/`Licor Mp`).
- **Join a `revenue_maestro_sku` por `material_id = sku`:** el `sku` es unico (1,340 filas), asi que
  no duplica, y la cobertura es del 100% del volumen Beer+Rtds. El nombre `` `Agrupador (Tipo 2.0)` ``
  requiere backticks.
- **Subcanales reclasificados en 2026** (ej. `Pe Of Tr Bod  Barrio` → `BODEGA`): el subcanal no es
  comparable con años previos, salvo los subcanales de `TERCEROS` (2025-2026). `canal_cliente` si es
  comparable.
- **No sumar con `dm_venta`:** el sell out DAS es la reventa del distribuidor de lo que ya le
  facturamos (sell in). Sumar ambos cuenta dos veces el mismo volumen.
- Queries curadas del informe de status DAS Sell Out (1YP 2027): `querys/Query_DAS_SellOut_*.sql`.
- **Cruce sell in vs sell out (2026-11-11):** sell in = `dm_venta` a clientes con
  `dm_cliente.unidad_negocio_revenue_volumen_meta = 'DAs'` (`querys/Query_DAS_SellIn_Mensual_Distribuidor.sql`).
  Sell out = `querys/Query_DAS_SellOut_Mensual_Distribuidor.sql`. **No hay llave comun:** un DAS tiene
  varios `cliente_id` en `dm_cliente` (ej. Dismar Huanuco 4 codigos, Bonanza 7+ con razones sociales
  que cambian: "Inversiones Bonanza del Oriente", "Inversiones Bonanza Rio Amazonas", "Grupo Bonanza
  S.A.C.") y el nombre difiere de `dm_das_venta.razon_social`. Se empareja **por nombre normalizado**.
  Cuidado: `dm_cliente.nombre` puede traer comas ("Grupo Bonanza Sociedad Anonima Cerrada, Grupo
  ..."), asi que no hay que parsear el resultado como CSV por coma.
  - Resultado YTD Ene-Oct 2026: los 8 DAS con reporte completo cuadran al **99.8%**. Bonanza (Iquitos)
    reporta solo el ~73% de su sell in. Ucayali Beer reporta sell out solo desde Ago'26. Hay **13 DAS
    chicos** (en 5 GV, incluidas Huancay Ch y Pucall Hco) con sell in pero **sin** sell out en
    `dm_das_venta` (~55 mil HL, ~7% del sell in DAS de CO).

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
  **Formula confirmada empiricamente (2026-09-08, detalle diario de Cristal 650 RB en SJ91/Iquitos,
  agosto 2026):** `hl_so_brand_pack = horas_oos_brand_pack * hl_pv_promedio_bp` — horas apagado ese
  dia multiplicadas por la velocidad de venta promedio (HL/hora) de ese brand_pack en ese CD. Es una
  **estimacion de demanda** ("lo que se habria vendido al ritmo habitual"), no venta perdida
  contabilizada, y depende de un promedio movil de 6 meses que cambia dia a dia (dos dias con horas
  OOS similares pueden dar HL perdido muy distinto). **Ojo:** no todos los dias del mes tienen fila
  para cada combinacion CD×brand_pack (ej. ese caso solo tuvo 28 de 31 dias de agosto con registro) —
  el % uptime se calcula sobre los dias con dato, no sobre el mes calendario completo.
- `hl_pv_promedio_bp` (double) — promedio de HL/hora a nivel brand_pack (ultimos 6 meses), el
  multiplicador usado en `hl_so_brand_pack` (ver arriba). **Denominador validado empiricamente
  (2026-09-08):** son horas **calendario** del periodo (dias x 24h), no horas efectivamente
  disponibles/sin quiebre. Validacion: HL real vendido de Cristal 650 (43 codigos SAP del mismo
  producto) en clientes del CD SJ91/Iquitos, feb-jul 2026 via `dm_venta` = 108.238 HL en 181 dias
  (4.344h calendario) => 108.238/4.344 ≈ 24,9 HL/hora, vs. promedio real de los 28 valores diarios
  de `hl_pv_promedio_bp` en agosto 2026 de ese mismo brand_pack/CD ≈ 26,0 HL/hora (rango 7,2-57,7) —
  coincide. (Intentar dividir por `horas_prendidas_brand_pack` de esta misma tabla NO cuadra: esa
  tabla no tiene cobertura completa hacia atras, solo 456h de dato en 3 de los 6 meses previos.)
  **Implicancia:** el promedio NO descuenta dias que el brand_pack ya estaba en quiebre en la
  ventana de 6 meses -> si viene de quiebres sostenidos, el promedio (y por tanto `hl_so_brand_pack`)
  puede subestimar la demanda real perdida.
- `flag_preventa_dia` (int) — 1 si hubo preventa del brand_pack ese dia (ultimos 6 meses).
- `max_length_of_time_days` (int) — maxima duracion de evento OOS en el grupo (dias).
- `skus_en_quiebre` (bigint) — cantidad de SKUs distintos con evento OOS valido en el dia.
- `fecha_proceso_dbks` (string) — timestamp de ejecucion del ETL.
- `skus_brand_pack_list` / `skus_oos_list` (string) — listas de SKUs (separadas por coma).

**Metadata:** catalogo `brewdat_uc_mazana_dev`, formato Delta, tabla MANAGED via Volume (sin fecha
de creacion/owner expuestos por `DESCRIBE EXTENDED` en este tipo de tabla).

**Filtrar por categoria (Cervezas/Licores/RTD, alcance de negocio confirmado 2026-08-31):**
esta tabla no tiene `material_id`, solo `brand_pack` (marca + sub-marca/sabor + presentacion, ej.
`Cusqueña Malta 310 NRB`). Un join EXACTO de `brand_pack` contra
`pe_portfolio_material.brand_pack` **falla para ~36 valores** (validado ago'26, Centro Oriente):
sub-marcas/sabores que no existen como `brand_pack` en el maestro (`Cusqueña Malta/Trigo/Dorada/
Cero/Quinua`), `Mikes` sin apostrofe vs `Mike's` en el maestro, formatos nuevos (`KEGS`). Se
resuelve haciendo el join por **prefijo de `brand`** (marca base, sin sub-marca/sabor/presentacion)
contra la lista de marcas Cervezas/Licores/RTD del maestro (`v.brand_pack ilike concat(brand,'%')`,
+ variante sin apostrofe) — valida que no genere fan-out (claves `mes+fecha+centro+brand_pack`
unicas) antes de confiar en el agregado. Deja solo 18 `brand_pack` sin matchear, todos de
categorias fuera de alcance (`Guaraná`/`Viva` = Gaseosas, `Maltin Power` = Malta) salvo `P.Fresh`
(pendiente de aclarar, volumen bajo). Query de referencia:
`querys/Query_Sku_Uptime.sql`.

**Ojo con el % Uptime resultante:** incluso con el filtro de categoria bien hecho, el % uptime
ponderado (`sum(horas_prendidas)/sum(24h)`) sobre TODO `activo_en_cd=1` de Cervezas+Licores+RTD da
~41% (ago'26, Centro Oriente) — muy por debajo del ~96% del ejemplo de la capacitacion del KPI
SKU Uptime. Esto confirma que el scope de `activo_en_cd=1` sigue siendo mas amplio que el listado
oficial de SKUs que el equipo de Planning define a inicio de mes para medir el KPI (ver definicion
en `CLAUDE.md` — ese listado sigue sin conseguirse, es un input externo mensual, no derivable de
esta tabla sola). No reportar el ~41% como el KPI oficial de SKU Uptime sin esa aclaracion.

**Ultimo dia del mes con corte parcial (confirmado 2026-10-07):** el ultimo dia calendario de cada
mes trae `horas_disponibles` < 24 (31-ago: 17.04h; 30-set: 16.61h — este ultimo sigue asi 7 dias
despues del cierre, o sea no se completa con el tiempo). **Hipotesis (no verificada con Data
Engineering):** la corrida del dia siguiente completa d-1 dentro del mismo mes, pero para el ultimo
dia del mes ya cae en otra particion y no lo completa. Evidencia a favor (2026-10-07): el dia en
curso (07-oct) trae 11.53h por fila mientras que 01 a 06-oct vienen completos (24h). Consecuencia
para MTD: el dia en curso siempre viene parcial -> cortar a d-1. Efecto: el maximo de
`horas_disponibles_mes` por combinacion CD x brand_pack es
`dias_operativos x 24 - ~7h`, no un multiplo exacto de 24 (ej. setiembre con 26 dias operativos:
max 616.61h, no 624h). Es un sesgo menor y parejo entre meses; no invalida el % uptime ponderado.
**Filas solo en dias con quiebre (validado 2026-11-10, `P.Callao 305 RB` en SJ90/SJ97, ago-oct'26):**
a nivel CD x brand_pack la tabla trae fila **solo los dias con OOS > 0** (0 filas con `horas_oos = 0`).
Por eso `sum(horas_prendidas)/sum(horas_disponibles)` de un solo brand_pack mide el uptime **de los
dias con quiebre**, no del mes. Para el % del mes usar `horas_oos / (24 x dias operativos del mes)`.
Query: `querys/Query_Pucallpa_Pilsen305x24_Venta_OOS_Mensual.sql`.
**Historia y huecos (validado 2026-11-15):** hay datos todos los dias desde **Ene'25** para los 11 CDs
de Centro Oriente (antes de 2025 no hay). Hueco: **SJ92/Moyobamba sin filas en Jun y Jul'26** (no es
cero quiebre, es ausencia de dato; excluir esos CD-mes al comparar). **Falso positivo del join por
prefijo:** `Cristalina 500 PET` (agua, `dm_material.estratificacion = 'Agua'`) entra por el prefijo de
marca `Cristal` — excluir `brand_pack not ilike 'Cristalina%'`. Las variantes `Mikes Limon/Limón`,
`Maracuya/Maracuyá`, `Arandanos/Arándano` son el mismo brand_pack con nombre cambiado en el tiempo.
`skus_oos_list` son codigos SAP que cruzan con `dm_material.material_id` (sin ceros a la izquierda).
Query del deep dive mensual Ene'25-Oct'26: `querys/Query_OOS_DeepDive_GV_CD_BrandPack_Mensual.sql`.
**Cobertura por dia:** agosto (31/31) y setiembre (30/30) tienen filas todos los dias a nivel
agregado de Centro Oriente (80-140 combinaciones por dia; domingos ~20% mas bajos). Queries por
mes de la prueba de OOS: `querys/Query_OOS_Gerencia_CD_BrandPack_Agosto2026.sql`,
`..._Setiembre2026.sql` y `..._Octubre2026_MTD.sql` (misma metodologia: domingos excluidos, SJ01 y
BK31 fuera; octubre corta en d-1). Fuentes HTML de los dashboards en la raiz del proyecto:
`radar_oos_setiembre.html` y `radar_oos_octubre_mtd.html` (el de agosto solo vive publicado).

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

**TRAMPA confirmada (2026-08-31):** el filtro `lgort IN ('IQ01','IQ24')` que trae `Query_Stocks_SAP.sql`
en la CTE `stock` **esta activo por defecto** (no comentado, a pesar de que el comentario de arriba
en el archivo dice "por defecto TODOS") — son codigos de almacen **especificos de Iquitos/SJ91**
(el centro por defecto del archivo). Al reusar la query para OTRO centro (probado con BK80/Cusco)
sin sacar ese filtro, devuelve **0 filas silenciosamente** (no error) porque ese centro no tiene
almacenes con esos codigos. **Sacar ese filtro de `lgort` al cambiar de centro**, salvo que se
confirmen los codigos de almacen equivalentes para el centro nuevo.

**ALERTA de confiabilidad en `CalDisFinal` (detectada 2026-08-31, sin resolver):** validado para
2 centros muy distintos en performance de OOS — Iquitos/SJ91 (14.7% uptime, el peor de Centro
Oriente) y Cusco/BK80 (69.5% uptime, el mejor) — **en ambos, practicamente el 100% de los
materiales Backus dan `CalDisFinal = 0`** (44/44 en Iquitos, 82/84 en Cusco), incluso con
`Stock_Disp` (stock fisico) sano/alto (ej. Pilsen Callao 1000ml en Cusco: 42,627 cajas fisicas,
`CalDisFinal` = 0 igual). Como el mismo patron aparece en el CD con mejor Y el de peor uptime,
**`CalDisFinal` no esta explicando diferencias reales de disponibilidad entre CDs — probablemente
es un artefacto de como se reconstruye el estado "abierto" de `VBBE`/`RESB`** (tablas CDC), no
un reflejo de que el stock este genuinamente 100% comprometido. Ademas contradice la unica
validacion previa documentada arriba (pedidos subestimados 28 CA vs 27,191 CA reales — si algo,
`CalDisFinal` deberia verse mejor de lo real, no en cero). **No usar `CalDisFinal`/`Disponible_Final`
para explicar gaps de uptime/OOS entre CDs sin validar antes con Data Engineering (Javier, autor
original) — `Stock_Disp` (stock fisico crudo) si parece confiable y se puede usar solo.**

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

**`periodo_promo` — confirmado por el usuario (2026-09-01):** `FM` = **Full Month**, es decir la
promo esta prendida/activa **todo el mes** (no es "foco mensual" ni un periodo parcial dentro del
mes). Pendiente confirmar otros valores de `periodo_promo` si aparecen (no observados aun fuera de
`FM`).

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

**OJO — `estado='R'` NO sirve como filtro de "elegibilidad historica" de un mes ya cerrado
(hallazgo 2026-09-01, caso Foco ON / material 7497 en Tarapoto):** al calcular adherencia
(clientes que compraron bajo la promo / clientes elegibles) para agosto 2026 consultando **en
septiembre**, clientes que **si compraron** bajo una fila de `dm_promocion` con vigencia
`desde`/`hasta` dentro de agosto aparecian con `estado='D'` en esa misma fila — es decir, el
`estado` parece reflejar el estado **actual/de ultimo batch cargado** (se "desactiva" a `D` en
cuanto el periodo de vigencia cierra o se sube una tanda nueva de elegibilidad), no si la promo
estuvo vigente/fue usada en su momento. Filtrar `estado='R'` para medir el universo elegible de un
mes pasado subestima la poblacion real (en el caso validado, daba mas "adheridos" que "elegibles",
resultado imposible >100%). **Para elegibilidad historica, usar la sola existencia de la fila
cliente x material x mes en `dm_promocion` (sin filtrar `estado`)**, o cruzar contra `desde`/
`hasta` vs. la fecha real de venta si se necesita mas precision. Reservar el filtro `estado='R'`
para medir el universo **vigente hoy** (mismo uso que valida la tabla de arriba).

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
  (2026-08-29, version final):**
  - `flag_venta` = el cliente compro el SKU especifico de la promo (con o sin descuento aplicado).
  - `flag_linea` = el cliente compro algo de la misma **familia** del SKU de la promo, entendiendo
    "familia" como la misma `estratificacion` del SKU de la promo (no necesariamente el mismo SKU).
  - `flag_promo` = el cliente compro el SKU **y ademas se adhirio a la promo** (adherirse = compro
    la promo, es decir efectivamente se le aplico el descuento/mecanica) — mas estricto que
    `flag_venta`, que no exige que la promo se haya usado.
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

## Tablas de tracking diario: plan y preventa (explorado 2026-11-04)

Usadas en `querys/Query_Pucallpa_Tracking_Diario.sql`, query propio del usuario para seguir la GV
Pucallpa (`TIPO` = `FACT`, `PLAN`, `PV D+1`, `PV FUT`). Esquemas tomados de `DESCRIBE TABLE EXTENDED`.

### `slv_maz_dataexperience_peru_revenue.revenue_h_pv_planeada` — Plan de entrega

- **Campos:** `NumeroPedido`, `PosicionPedido`, `FechaCreacionPedido`, `FechaPlan`, `CodCliente`,
  `ZonaPV`, `Regional`, `Centro`, `ClaseDocumento`, `Tipo`, `SKU`, `Linea`,
  `OficinaVentasRegional`, `GrupoGerencia`, `CodigoCanalSubcanalLocal`, `HLPlaneado`.
- **Es historica:** conserva fechas pasadas, asi que sirve para comparar plan vs. facturado por dia.
- Solo trae HL. CE se deriva con `HL x 13.44086022`.
- **Validacion Pucallpa, Beer+Rtds, Oct'26:** plan 46,260.5 HL vs. facturado 46,419.5 HL = 100.3%,
  contando solo dias con plan y venta. Hay dias atipicos (11.10 = 250%, 03.11 = 112%).

### `slv_maz_dataexperience_peru_dm.dm_preventa_flash_actual_fe` — Preventa del dia siguiente

- **Campos principales:** `FechaCreado`, `FechaEntrega`, `CodCentro`, `ClaseDoc`, `CodCliente`,
  `Pedido`, `PosicionPedido`, `CodMaterial`, `Anulado`, `MotivoAnulacion`, `VolumenHL`, `VolumenCA`,
  `VolumenCE`, `ValorVenta`, `Dscto`, `ValorNeto`. Tambien trae su propia jerarquia
  (`Direccion`, `Gerencia`, `Supervisor`).
- **Es una foto de la siguiente fecha de reparto, no de hoy+1:** el sabado 31.10 ya traia el lunes
  02.11 desde las 09:00 de Lima, y seguia asi el domingo. Se actualiza cada hora (Delta, version por
  corrida) y permite ver versiones pasadas con `TIMESTAMP AS OF`, solo hasta 7 dias atras
  (`deletedFileRetentionDuration` = 168 h).
- `Anulado` es string (`'0'`/`'1'`).
- **No cuadra exacto con `dm_preventa`:** para entrega 05.11 en Pucallpa, todas las categorias, sin
  anulados: 1,939.5 HL aqui vs. 2,071.4 HL en `dm_preventa` (`flujo = 1`). Causa pendiente.

### `slv_maz_dataexperience_peru_dm.dm_preventa` — Preventa con historico

- **Particionada por `mes`.** Trae `direccion`/`gerencia` propias (usar las de `dm_cliente`).
- **Fechas:** `fecha_preventa`, `fecha_preferente_entrega`, `fecha_entrega`, `fecha_planificado`.
- **Volumen:** `hl`, `hl_planeado`, `hl_entregado`, `hl_rechazado`, `cajas_fisicas`.
- **Estado:** `flujo`, `facturado`, `estado`, `motivo_anulacion`, `on_time`, `in_full`.
- **Otros:** `numero_preventa`, `numero_preventa_bees`, `posicion_numero`, `cliente_id`,
  `material_id`, `tipo_origen_pedido`, `clase_preventa`, `promocion_id`, `combo_id`, `valor_neto`.
- El significado de cada valor de `flujo` esta por confirmar: el query usa `flujo = 1`, y `flujo = 2`
  solo mostro volumen en una fecha ya pasada (03.11).
- `hl_planeado` vino nulo en todas las filas revisadas (entregas 03-06.11, Pucallpa).

### Observaciones al combinar los 4 tipos (corrida del 2026-11-04, Pucallpa)

- **CE de NABS no es comparable:** `dm_venta.caja_equivalente` da ~17.58 CE/HL en NABS, mientras
  `PLAN`, `PV D+1` y `PV FUT` usan 13.44. En Beer+Rtds si coincide (13.44). Comparar en HL o
  solo Beer+Rtds.
- **Doble conteo el sabado (confirmado con la foto del 31.10, 18:00 de Lima):** `PV FUT` excluye
  solo hoy+1 (domingo), pero la foto flash ya trae el lunes, asi que ese dia entra en `PV D+1` y en
  `PV FUT`. Fueron 646 documentos y 1,518.7 HL duplicados (1,242.4 HL en Beer+Rtds), un 48.6% de
  inflacion sobre la preventa total. Por la misma logica aplicaria a la vispera de un feriado sin
  reparto (sin verificar). **Corregido el 2026-11-04:** `PV FUT` ahora excluye las `FechaEntrega`
  de la tabla flash en vez de hoy+1. Al reconstruir el 31.10 con esa regla, el lunes queda solo en
  `PV D+1` (total 3,086.4 HL). Quedan fuera de ambos bloques los pedidos con preferente en esa fecha
  que no estan en flash (39.3 HL ese dia).
- **Preventa fuera de los 4 tipos:** con `fecha_preferente_entrega` = hoy, `flujo = 1`, sin anular y
  sin pedido en `revenue_h_pv_planeada` hubo 474 HL / 183 docs el 04.11, tras bajar de 772 HL / 299
  docs en una corrida previa del mismo dia, y 263 HL / 104 docs el 03.11. Casi todos tienen
  `fecha_entrega` y `fecha_planificado` nulas, y ninguno esta en la tabla flash. De los 263 HL del
  03.11, 223 HL son de clientes que facturaron ese dia (cruce por cliente, no por documento) y 34 HL
  de clientes sin venta ni plan.
- **`dm_preventa` y la tabla flash cambian durante el dia:** entre dos corridas del 04.11, la
  preventa con preferente 04.11 bajo 303 HL, la del 05.11 subio 101 HL y la del 06.11 subio 121 HL.
  Compatible con reprogramacion, sin confirmar a nivel documento. Anotar la hora al comparar cifras.
- **`FACT` no filtra `cliente_id > 10000000`, a proposito** (decision del usuario, 2026-11-04), a
  diferencia de `PLAN`, `PV D+1` y `PV FUT`. Asi conserva 10.88 HL MTD al 03.11, casi todo de clientes
  genericos `VARIOS PN` (`200565`-`200567`).
- `revenue_maestro_sku` no duplica el join (1,340 filas = 1,340 SKUs).
- **HL a caja fisica:** `CF = HL x 100000 / (dm_material.volumen x dm_material.unidades_caja)`, con
  `volumen` en ml por unidad. En las 6 categorias del tracking (Pucallpa, Oct-Nov'26) solo 1 SKU se
  desvia mas de 2% contra `dm_venta`, con volumen casi nulo. Coincide exacto con `VolumenCA` en
  `PV D+1` (41,340) y con `cajas_fisicas` en `PV FUT` (72,216) el 04.11. **No sirve fuera de esas
  categorias:** sale muy inflada en `dm_venta.estratificacion` `Licor Mp` (ej. Ron Cartavio Black
  250 ml x1, 37 veces), `Mercaderias Cigarros`, `Comestibles` y `Cuidado Personal`. En
  `revenue_maestro_sku.categoria` esos SKU son `Marketplace` o no tienen categoria, asi que el tracking
  ya los excluye. `13.44` es justo el factor de una caja de 620 ml x12.
- **`dm_venta` tiene lineas con `hl = 0` y `caja_fisica > 0`:** en Pucallpa Nov'26 (al 03.11) son
  ~16,626 de 62,523 CF, el 26.6%. ~16,550 son clase `BKIP` facturada a los clientes `ISJ90` (CD
  Huanuco) e `ISJ93` (CD Tingo Maria), o sea a los propios CD y no a POCs; parecen traslados, sin
  confirmar. Caen bajo el supervisor Jose Trujillo. Sin ellas, HL x factor por SKU cuadra con la caja
  fisica real (45,898 CF), asi que `SUM(caja_fisica)` sin filtrar sobreestima la venta en cajas.

---

## `slv_maz_dataexperience_peru_dm.dm_volumen_meta` — Cuota de volumen (confirmado por el usuario, 2026-11-23)

**Que es:** la tabla de **cuotas** de volumen ("meta"). El usuario la confirmo como la fuente de cuota
(2026-11-23). Explorada con `DESCRIBE TABLE EXTENDED` y datos de Centro Oriente sep-nov'26
(`querys/Query_Cuota_dm_volumen_meta_vs_Real_Pucallpa.sql`).

**Columnas (16):** `mes` (string 'YYYYMM'), `direccion`, `gerencia`, `material_id`, `zona_pem`,
`zona_comisional`, `unidad_negocio`, `unidad_negocio_rtm`, `canal`, `subcanal`, `cliente_id`, `fecha`
(date), `accion`, `hl`, `caja_fisica`, `caja_equivalente` (decimal(38,30)). Delta externa, sin particion
visible en el DESCRIBE: filtrar siempre por `mes`.

**Grano:** mes x cliente x material. `fecha` es siempre el dia 1 del mes (una sola fecha por mes): es una
cuota **mensual**, no diaria. `accion` = metodo con que se repartio la cuota a cada POC:
`SPLITEAR POR POC (HL SUGERIDO)` (casi todo el volumen) o `SPLITEAR POR POC (HL HOMOGENEO)` (marginal).
Sumar ambas para el total.

**Alcance de categorias:** trae Cervezas, Licores, Ready To Drink, Gaseosas, Agua y Maltas (via
`dm_material.estratificacion`); no trae Marketplace. Para comparar con los reportes ejecutivos usar
Beer+Rtds (`estratificacion IN ('Cervezas','Licores','Ready To Drink')`).

**Gerencia:** `dm_volumen_meta.gerencia` coincide con `dm_cliente.gerencia` para Pucallpa (mismo total en
oct y nov'26), pero por la regla vigente usar `dm_cliente` (join por `cliente_id`).

**Cifras de referencia GV Pucallpa (`PE Ger P4 Pucall Hco`, HL):**

| Mes | Cuota Beer+Rtds | Cuota Nabs | Real Beer+Rtds | Cumplimiento |
|---|---|---|---|---|
| Oct'26 | 48,415 | 4,879 | 46,421 | 95.9% |
| Nov'26 | 44,869 | 4,570 | (en curso) | |

Nov'26 en Pucallpa: 34 zonas comisionales y 5 supervisores con cuota. Cuota total GV Pucallpa (todas las
categorias) ~49.4 mil HL en nov, ~53.3 mil en oct.

**Pendiente:** confirmar con el usuario si la cuota "oficial" de la GV es la de Beer+Rtds o la total con
Nabs, y si hay cuota para Marketplace en otra tabla.

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

## Fuentes externas (fuera de Databricks)

### `MetasBrandDistribution2026.xlsx` — Metas 2026 de Brand Distribution

**Ubicacion:** `C:\Users\aldoz\OneDrive\Claudio\MetasBrandDistribution2026.xlsx` (hoja unica
`Hoja1`), entregado por el usuario 2026-09-02.

**Grano:** fila = Direccion/Gerencia x Tipo (Sell In / Sell Out), columnas = un mes 2026 cada una
(ene-dic). Filas: `PE Dir Centro Orient` (Sell In + Sell Out), `PE Ger P4 Pucall Hco` (solo Sell
In), `PE Ger P4 Huancay Ch` (solo Sell In), `PE Ger P4 Tarapoto` (Sell In + Sell Out), `PE Ger P4
Iquitos` (Sell In + Sell Out), `PE Ger P4 DA Jun Puc` (solo Sell Out) — coincide exacto con la
regla de "total oficial por gerencia" ya validada (ver CLAUDE.md).

**Como estan armados los valores (confirmado por el usuario 2026-09-02):** enero-marzo 2026 son
el **YTD real ya facturado** (coinciden exacto con `pe_portfolio_hm_brand_distribution`), abril-
diciembre son la **proyeccion/meta** del resto del año (por eso tienen decimales). La **meta anual
= suma de las 12 columnas** (YTD real + proyeccion), no solo la parte proyectada. Releer el
archivo con el skill `xlsx` cada vez que se use — se va actualizando mes a mes (el mes que cierra
pasa de proyectado a real).

---

## Pendiente de confirmar (no asumir, preguntar al usuario o validar con datos)

- **Confirmado por el usuario (2026-08-28): `direccion_historia`/`gerencia_historia` y
  `direccion_venta`/`gerencia_venta` NO siempre coinciden entre si** (en el unico caso validado
  hasta ahora si coincidieron, pero no es la regla general) — falta un caso concreto de divergencia
  para entender que distingue a cada una y cuando usar una u otra.
- Mecanismo de expansion de las promos "masivas" (campos `*_masivo` en `dm_promocion`) hacia
  clientes individuales — no confirmado como se traduce un criterio masivo (ej. gerencia+marca) en
  las filas cliente x material que trae la tabla.
- Nombre exacto del campo de cruce `pe_promo_adherenciadiaria` → `dm_combo` cuando
  `proyecto = 'combos_promos'` (no verificado con una consulta real todavia).

## Notas 2026-11-13 (v6 ejecutiva PR 2026 & 1YP 2027)

- **`dm_material.marca` de Pilsen Fresh:** los SKUs nuevos desde Ago'26 (23383, 23384, 23385, 23550) vienen con marca
  `Pilsen Callao Fresh`, no `Pilsen Fresh`. Para sumar la marca completa usar `marca IN ('Pilsen Fresh','Pilsen Callao Fresh')`.
  Con eso cuadra con la serie por brand pack del deck (1.40/1.42/1.29 mil HL en Ago/Set/Oct'26).
- **Nolo** (definido por el usuario): `dm_material.marca IN ('Corona Cero','Cusqueña Cero Trigo')`. Existen tambien
  `Pilsen Cero` y Cristal Cero (marca `Cristal (Peru)`), que el usuario no incluyo.
- **Flying Fish:** `dm_material.marca = 'Flying Fish'`, estratificacion Cervezas, venta en CO desde Feb'26.
- **`pe_portfolio_hm_brand_distribution`** tiene historia desde Ene'23 (no solo desde Ene'25) y acepta join a
  `dm_material` por `material_id` para filtrar por marca. Queries: `querys/Query_Brand_Distribution_Oficial_*`,
  `querys/Query_Expansion_PilsenFresh_Nolo_FlyingFish_*`.

**Sesgo del recalculo desde venta en Lima (validado 2026-11-21):** el metodo "1 punto por cliente-material con
`caja_fisica` > 0" sobre `dm_venta` + `dm_cliente` da en `PE Dir Lima` entre +4% (Lima Norte) y +13% (Lima Centr)
por encima de esta tabla, mucho mas que en CO (+0.7% a +1.1%). El sesgo es estable de un mes al siguiente
(Set vs Oct'25 difieren <0.3 pp) pero sube ~2-3 pp en 2026 vs 2025, asi que **no sirve comparar recalculo 2026
vs oficial 2025 directo**. Para estimar un mes sin carga, dividir el recalculo por el ratio recalculo/oficial del
mes previo del mismo año. `PE Ger P1 May Ev Lim` cuadra exacto. `PE Ger P1 Central KA` tiene clientes en
`dm_cliente` bajo Lima pero 0 BD en esta tabla. Query: `querys/Query_Lima_BD_Oct26_Estimado.sql`.
