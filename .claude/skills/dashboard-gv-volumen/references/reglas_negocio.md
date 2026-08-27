# Reglas de negocio del dashboard GV Volumen

Estas reglas ya estan validadas por el usuario (ver `CLAUDE.md` y `BITACORA_TABLAS.md` en la
raiz del proyecto) y estan **horneadas en las plantillas SQL y en el dashboard** — no hace
falta reconfirmarlas cada vez que se corre el skill para gerencias nuevas. Si el usuario pide
explicitamente una excepcion (ej. "esta vez si incluye San Mateo"), avisale que te estas
apartando de la regla vigente antes de hacerlo.

## Categorias (Beer / Rtds / Nabs)

- **Beer** = `estratificacion IN ('Cervezas','Licores')`
- **Rtds** = `estratificacion = 'Ready To Drink'`
- **Nabs** = `estratificacion IN ('Gaseosas','Agua','Maltas')`
- Se excluyen del alcance otras estratificaciones que puedan aparecer en `dm_venta`
  (marketplace, comestibles, cigarros, merchandising, etc.) — el filtro
  `estratificacion IN (...)` en cada query ya las deja afuera.
- **Regla fija:** excluir siempre la marca **San Mateo** de la categoria Agua
  (`AND NOT (v.estratificacion = 'Agua' AND v.marca = 'San Mateo')`).
- El dashboard tambien muestra dos filas de referencia en la seccion Categoria (no se suman de
  nuevo al Total): **Beer + Rtds** y **Beer + Rtds + Nabs** (esta ultima equivale al Total).
- El filtro **Categoria** del toolbar es multi-select y es **global**: recalcula Total,
  Categoria, CD, Canal, Marca y Formato usando solo las categorias marcadas.

## Canal

- Campo: `dm_cliente.unidad_negocio_revenue_volumen_meta`.
- Valores observados y su equivalencia con la nomenclatura del rol (PPM/RGM):
  `DSD OFF`, `DSD ON`, `Mayoristas` (= **WHL**), `Eventos` (= **EVE**),
  `Key Accounts` (= **KA**), `DAs` (= **DAS**), y un residual `High End`.
- **Regla fija:** el canal `High End` (volumen marginal) se **pliega dentro de `DSD ON`** — ya
  resuelto en el template (busca las claves `...|High End` en `IDX_CANAL` y las suma a la
  clave `...|DSD ON` correspondiente antes de borrarlas).
- **No confundir** con `dm_venta.unidad_negocio_venta` (u `unidad_negocio`/
  `unidad_negocio_revenue`), que es un campo distinto con otro dominio de valores
  (`Off Premise`, `On Premise`, `Mayoristas y Eventos`, `Key Accounts`, `Consumidor`, `DAs`) y
  NO sirve para este mapeo.
- Orden de columnas fijo (no ordenar por tamano): DSD OFF, DSD ON, WHL, EVE, DAS, KA.

## Marca

- Campo: `dm_venta.marca` directo (sin transformar).
- Cardinalidad manejable (~30-45 marcas por gerencia). El dashboard calcula un **orden fijo por
  volumen** (descendente, sobre el ultimo periodo anual disponible) una sola vez por gerencia
  (`computeSortedDims`) — no reordena en cada render para que las filas no salten al cambiar de
  filtro/periodo.
- Los nombres de marca en la fuente tienen inconsistencias de capitalizacion (ej. "golden" vs
  "MIKES H APPLE" vs "Mikes H MARACUYA") — **no normalizar**, mostrar tal cual viene del dato;
  es asi en el sistema de origen.

## Formato (pack)

- Campo: `pack` de `slv_maz_dataexperience_peru_revenue.revenue_maestro_sku`, join
  `dm_venta.material_id = revenue_maestro_sku.sku`.
- Tabla de **carga manual** (ver seccion de esa tabla en `BITACORA_TABLAS.md`) — **validar
  cobertura de join cada vez que se corre para un alcance/periodo nuevo**: revisar que
  `COALESCE(r.pack, 'Sin mapear')` no traiga volumen relevante en "Sin mapear". Validado
  2026-08-27 para las 4 gerencias de Centro Oriente: 100% de cobertura (0 HL sin mapear).
- Cardinalidad manejable (~20-24 formatos por gerencia). Mismo criterio de orden fijo que Marca.

## Centro de Distribucion (CD)

- Campo: `dm_cliente.centro` (y `centro_id` si se necesita el codigo corto tipo `BK##`/`SJ##`).
- **`dm_cliente` es una foto UNICA/vigente, no historica por mes** — un cliente que cambio de
  CD/canal en el periodo aparece siempre bajo su clasificacion **actual**, incluso para ventas
  de anios anteriores. Advertido en las notas del dashboard, no es un bug.
- **Cada gerencia tiene su propio subset de CD "reales"** — no asumir que son los mismos que
  otra gerencia, ni decidirlo solo mirando el volumen. Antes de armar el dashboard para
  gerencias nuevas, correr `assets/querys/explorar_centros.sql` (mes mas reciente nomas, todas
  las gerencias del run juntas) y **preguntarle al usuario** cuales CD son los operativos de
  cada una.
- **Patron "canal DAs" (importante, no es intuitivo):** un CD puede aparecer con volumen NO
  trivial en una gerencia donde geograficamente no corresponde, porque los Distribuidores
  Autorizados (canal `DAs`) se abastecen/asignan al CD mas grande o cercano sin importar bajo
  que gerencia comercial facturan sus ventas. **Caso confirmado (2026-08-27):** en
  `PE Ger P4 Tarapoto`, el CD `CD Pucallpa` aparecia con ~25K HL/mes (mas grande que los 3 CD
  geograficos reales de Tarapoto juntos) — se confirmo con
  `explorar_cd_sospechoso_por_canal.sql` que es **100% canal DAs**. El usuario decidio
  **incluirlo** en el `cd_list` de Tarapoto (para no perder ese volumen real), pero en otra
  gerencia el mismo patron podria resolverse distinto (ej. Iquitos tenia el mismo cruce
  CD Pucallpa+DAs pero con 0 HL — ahi si es puro ruido y se excluye). **No hay una regla
  automatica correcta para esto — siempre presentarselo al usuario con el desglose por canal y
  dejar que decida.**
- Cuando el `cd_list` de una gerencia excluye CD marginales, el Total "headline" (KPIs de
  arriba, sin restriccion de CD) puede quedar **por encima** del Total que sale de sumar el
  `cd_list` curado — es esperado, no un error de cuadre (`verify_dashboard.js` imprime esta
  diferencia por gerencia para que la revises).
- **Gerencias de otra naturaleza (ej. "DA" = Distribuidor Autorizado) no entran en el mismo
  patron de gerencia geografica + CD curado-excluyente.** Confirmado por el usuario:
  `PE Ger P4 DA Jun Puc` es un canal de distribuidores autorizados (100% canal `DAs`), no una
  zona geografica — sus CD saltan por varias regiones del pais (incluye uno en Ate/Lima) y **eso
  es su operacion normal, no ruido a excluir**. Quedo afuera del primer run de Centro Oriente
  (4 gerencias) mientras se validaba el patron, y se agrego despues con un `cd_list` que incluye
  **todos** los CD que aparecen para ella, sin curar/excluir ninguno como "marginal" (a
  diferencia de las gerencias geograficas, donde curar es la norma). Si aparece una gerencia con
  nombre/prefijo raro o cuyos CD no forman un cluster geografico coherente, preguntarle al
  usuario si aplica este mismo criterio ("incluir todos") en vez de asumir que hay que curar una
  lista chica como con las demas.

## Gerencia multi-select y el bug de CD compartidos entre gerencias

El selector **Gerencia** del toolbar es multi-select (igual que Categoria y Centro): con todas
las gerencias marcadas se ve el total de la Direccion completa; desmarcando se aislan una o
varias gerencias puntuales. El filtro **Centro** del toolbar muestra la **union** de los
`cd_list` de TODAS las gerencias seleccionadas (para poder elegir CD de cualquiera de ellas
sin tener que cambiar de gerencia).

**Bug real encontrado y corregido (2026-08-27):** un mismo nombre de CD (ej. "CD Pucallpa", "CD
San Benedicto I (Ate)") puede estar **curado-incluido para una gerencia y curado-excluido para
otra**. Ejemplo real: Tarapoto excluye deliberadamente `CD San Benedicto I (Ate)` de su
`cd_list` (volumen de paso/marginal para Tarapoto), pero ese mismo CD SI esta en el `cd_list` de
`DA Jun Puc` (porque ahi es real). Si `sumBase`/`sumDim` sumaran cualquier `(gerencia, centro)`
donde `centro` este en la seleccion COMPARTIDA del toolbar (la union), entonces con Tarapoto +
DA Jun Puc seleccionadas a la vez, el volumen de Tarapoto en `CD San Benedicto I (Ate)` — que se
supone excluido para Tarapoto — se colaba de vuelta (se detecto ~4,900 HL/mes de diferencia).

**La correccion (ya aplicada en el template):** `sumBase`/`sumDim` filtran, para cada gerencia
`g` de la seleccion, el `centro` contra `CD_DIMS[g]` (el `cd_list` propio de esa gerencia) antes
de sumar — nunca contra la lista compartida del toolbar. Asi, aunque el toolbar muestre "CD San
Benedicto I (Ate)" como opcion marcada (porque es valido para DA Jun Puc), Tarapoto simplemente
no le aporta nada a esa combinacion porque no esta en su propio `cd_list`.

**Si tocas la logica de agregacion del template, no rompas esta invariante** — `verify_dashboard.
js` tiene un chequeo dedicado (`multi_gerencia_union_vs_separado`) que compara el Total con
TODAS las gerencias + union de CD contra la suma de cada gerencia calculada por separado con su
propio `cd_list`; deben ser EXACTAMENTE iguales en cada mes. Si ese chequeo falla, es casi
seguro este mismo problema.

## Filtros base (siempre presentes)

- `v.indicadores_comerciales = 1` (KPIs comerciales oficiales).
- `v.gerencia = '<codigo transaccional>'` (o `IN (...)` para varias) — usar el campo de
  **`dm_venta`** (jerarquia al momento de la venta, aplicada de forma retroactiva/vigente tras
  la reestructuracion de gerencias de inicios de 2026 — ver `BITACORA_TABLAS.md`), no
  `dm_cliente.gerencia`. Ver `BITACORA_TABLAS.md` para la lista de gerencias conocidas y sus
  codigos exactos.
- `v.mes BETWEEN '{{MES_DESDE}}' AND '{{MES_HASTA}}'` — siempre filtrar por mes en `dm_venta`
  (tabla fact grande, particionada por `mes`).

## Metrica

- Solo **HL** (volumen). NR se saco del dashboard a pedido del usuario (2026-08-27) — si en el
  futuro lo piden de vuelta, es un cambio de alcance del template completo (toggle de metrica,
  formato de celdas, KPIs), no una excepcion puntual.

## Rango de anios / "ultimo mes disponible"

- Patron validado: ventana de **anios mostrados** `YEAR_MIN..YEAR_MAX` mas un anio oculto
  `YEAR_MIN-1` que solo sirve de base LY para `YEAR_MIN` (asi `YEAR_MIN` tambien tiene
  comparacion vs. anio anterior en vez de quedar sin dato). El primer run (Pucallpa solo) uso
  una ventana de 3 anios mostrados (2024-2026); el run multi-gerencia de Centro Oriente la
  redujo a 2 anios mostrados (2025-2026) a pedido del usuario — el template soporta cualquier
  ancho de ventana, es config (`YEAR_MIN`/`YEAR_MAX`), no esta hardcodeado a 2 ni a 3.
- `LATEST_MONTH` = el mes mas reciente con datos reales en `dm_venta` dentro de `YEAR_MAX` —
  **no asumir que es "el mes actual" del calendario**, confirmarlo con
  `SELECT max(mes) FROM dm_venta WHERE mes >= '{{YEAR_MAX}}01'` (dato hasta d-1).
- `LATEST_MONTH_IS_PARTIAL` = `true` si ese mes todavia no cerro — afecta el texto del
  footer/narrativa, no el calculo.

## Gerencia (selector, resumen)

- El template soporta **N gerencias** en una sola pagina (`GERENCIA_LIST`), con un selector
  **multi-select** (todas marcadas por defecto = vista de la Direccion completa; ver seccion
  dedicada mas arriba, "Gerencia multi-select y el bug de CD compartidos", para el detalle de
  como se agrega correctamente entre gerencias).
- Cada gerencia tiene su **propio `CD_DIMS`** (lista de CD confirmados) — al cambiar la
  seleccion de gerencias, el filtro Centro del toolbar se reconstruye con la UNION de CD de las
  gerencias seleccionadas y se resetea a "todos seleccionados".
- Los KPI de highlights usan `IDX_GERENCIA` (total SIN restriccion de CD, query aparte —
  `gerencia_mensual.sql`, sumado sobre TODAS las gerencias seleccionadas) para que el numero
  "headline" sea siempre el oficial/completo, sin importar que CD haya quedado fuera de algun
  `cd_list` curado.
