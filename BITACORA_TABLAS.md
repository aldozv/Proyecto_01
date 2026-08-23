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
- `direccion` / `gerencia` — jerarquia territorial **al momento de la venta**. Ojo: tambien existen
  `direccion_historia`/`gerencia_historia` y `direccion_venta`/`gerencia_venta` — no estan
  confirmados los criterios exactos de diferencia entre estas tres variantes; validar con el
  usuario antes de asumir cual usar si el analisis compara periodos donde el cliente pudo haber
  cambiado de territorio.

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

**Que es:** Maestro/atributos de cliente. ~1,151,927 filas (~137 MB). Primer campo es `mes`, lo
que sugiere que podria ser una foto mensual — **pendiente confirmar si hay multiples filas por
`cliente_id` (una por mes) o si es snapshot unico**; si es historica, filtrar por el `mes` que
corresponda para no duplicar al hacer join con `dm_venta`.

**Llave de negocio:** `cliente_id`.

**Campos que solemos usar:** `nombre`, `gerencia`, `centro`, `unidad_negocio_revenue_volumen_meta`.

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

## Pendiente de confirmar (no asumir, preguntar al usuario o validar con datos)

- Si `dm_cliente` es historica por `mes` o snapshot unico (afecta si hace falta filtrar por mes
  al unir con `dm_venta` para no duplicar filas).
- Diferencia exacta entre `direccion`/`gerencia` (de `dm_venta`, al momento de venta),
  `direccion_historia`/`gerencia_historia` y `direccion_venta`/`gerencia_venta`.
- Que significa exactamente `porte` en `dm_venta` (la query original lo menciona como pendiente
  de agregar) y como se relaciona con `PTR_Final` calculado en las consultas propias.
