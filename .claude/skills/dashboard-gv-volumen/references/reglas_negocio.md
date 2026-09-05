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
- El dashboard tambien muestra una fila de referencia en la seccion Categoria (no se suma de
  nuevo al Total): **Beer + Rtds**. (Antes tambien se mostraba "Beer + Rtds + Nabs", pero se
  quito a pedido del usuario 2026-08-31 por ser redundante con la fila Total.)
- El filtro **Categoria** del toolbar es multi-select y es **global**: recalcula Total,
  Categoria, CD, Canal, Marca y Formato usando solo las categorias marcadas.

## Canal

- Campo: `dm_cliente.unidad_negocio_revenue_volumen_meta`.
- Valores observados y su equivalencia con la nomenclatura del rol (PPM/RGM):
  `DSD OFF`, `DSD ON`, `Mayoristas` (= **WHL**), `Eventos` (= **EVE**),
  `Key Accounts` (= **KA**), `DAs` (= **DAS**), y un residual `High End`.
- **Regla fija:** el canal `High End` (volumen marginal) se **pliega dentro de `DSD ON`** — ya
  resuelto en el template via `foldHighEndCanal(idx)`, una funcion generica que busca claves
  cuyo segmento de canal (posicion 3, ver mas abajo) sea `High End` y las suma a la clave
  equivalente con `DSD ON` en esa posicion, antes de borrar la original. Se corre sobre los 6
  indices que llevan canal (`IDX_BASE`, `IDX_CANAL`, `IDX_MARCA`, `IDX_FORMATO`, `IDX_PACK`,
  `IDX_MARCAFORMATO`).
- **No confundir** con `dm_venta.unidad_negocio_venta` (u `unidad_negocio`/
  `unidad_negocio_revenue`), que es un campo distinto con otro dominio de valores
  (`Off Premise`, `On Premise`, `Mayoristas y Eventos`, `Key Accounts`, `Consumidor`, `DAs`) y
  NO sirve para este mapeo.
- Orden de columnas fijo (no ordenar por tamano): DSD OFF, DSD ON, WHL, EVE, DAS, KA.

## Filtro global de Canal (arquitectura del template, agregado 2026-09-03)

- A pedido del usuario, Canal paso de ser solo una seccion de detalle ("Por Canal") a ser
  tambien un **filtro global multi-select** en el toolbar (debajo de Categoria), que recalcula
  TODAS las secciones (Total, Categoria, CD, Canal, Marca, Pack, Formato, Marca × Formato) igual
  que Categoria/Centro ya hacian.
- **Para que esto funcione, `canal_meta` se agrego como dimension a CASI todos los indices** --
  `IDX_BASE`, `IDX_MARCA`, `IDX_FORMATO`, `IDX_PACK`, `IDX_MARCAFORMATO` (NO a `IDX_GERENCIA`,
  que sigue siendo el headline sin CD ni canal, ni tampoco un cambio estructural a `IDX_CANAL`,
  que ya tenia canal). La convencion de key es **siempre**
  `gerencia|centro|categoria|canal|...detalle opcional...` -- el canal va **siempre en la
  posicion 3** (0-indexed), sea cual sea el indice, para que `foldHighEndCanal` y el resto del
  codigo generico no necesiten un caso especial por indice.
- **`sumBase`/`sumDim` reciben un ARRAY de canales** (no un solo valor) porque estan sumando la
  seleccion del filtro global para una celda de OTRA dimension (ej. el Total de Enero sumando
  DSD OFF + DSD ON + WHL si esos 3 estan marcados). Firmas actuales:
  `sumBase(gerCodes, centros, categorias, canales, months)` y
  `sumDim(idx, gerCodes, centros, categorias, canales, dimVal, months)`.
- **Excepcion: la seccion "Por Canal" no usa `sumDim` con un array** -- ahi cada FILA ya es un
  canal especifico (no una seleccion a sumar), asi que usa una funcion aparte,
  `sumCanalRow(gerCodes, centros, categorias, canal, months)`, que lee `IDX_CANAL` directo con
  un solo canal, sin loop extra. Si en el futuro se agrega una seccion nueva donde una dimension
  ES la fila (como Canal hoy, o como Marca/Formato), replicar este patron: la dimension que
  identifica la fila NO se pasa como array, las que son filtro global SI.
- **Orden fijo (`computeSortedDims`/`computeSortedComboDims`) usa TODOS los canales
  (`CANAL_DIMS`), no el filtro activo** -- mismo criterio que ya se usaba para Centro/Categoria:
  el orden de las filas de Marca/Formato/Pack/Marca×Formato no debe saltar cuando el usuario
  toca el filtro de Canal, solo cuando cambia de gerencia. Por eso estas funciones ahora extraen
  `parts[4]` (o `parts.slice(4)` para combos) en vez de `parts[3]` -- el canal quedo en el medio
  y corrio el indice del dimVal real un lugar.
- **Bug real encontrado y corregido al implementar esto (2026-09-03):** las 5 queries que
  llevan `canal_meta` (Base/Marca/Formato/Pack/MarcaFormato) se corrieron primero, y
  `gerencia_mensual`/`canal_cd_categoria_mensual` (que no cambiaron de estructura) se dejaron
  con datos de un refresh **de horas antes**. El mes en curso (parcial, sigue acumulando
  facturacion durante el dia) no cuadraba entre ambos grupos de queries -- `verify_dashboard.js`
  lo detecto como fallos en `total_vs_canalsum`/`canal_filtro_vs_seccion_canal` justo en el mes
  parcial. **Leccion: cuando cambies el `SELECT`/`GROUP BY` de solo ALGUNAS de las 7 queries,
  igual volve a correr las 7 juntas, en la misma pasada**, si el rango incluye el mes en curso --
  no asumas que un archivo `raw_files` de un refresh anterior sigue siendo consistente con uno
  nuevo mientras haya un mes parcial de por medio.

## Marca

- Campo: `dm_venta.marca`, **normalizado en el SQL** (no en el template) — ver reglas abajo.
- Cardinalidad manejable (~25-30 marcas por gerencia tras normalizar). El dashboard calcula un
  **orden fijo por volumen** (descendente, sobre el ultimo periodo anual disponible) una sola vez
  por gerencia (`computeSortedDims`) — no reordena en cada render para que las filas no salten al
  cambiar de filtro/periodo.
- **Regla fija de normalizacion (confirmada por el usuario 2026-08-31):** los nombres de marca en
  la fuente traen inconsistencias de capitalizacion/variantes que hay que unificar en el `SELECT`
  de `Query_*_Marca_CD_Categoria_Mensual.sql` (CASE sobre `v.marca`, agrupando por el resultado):
  - `UPPER(v.marca) = 'GOLDEN'` → **`Golden`** (unifica "golden"/"Golden").
  - `UPPER(v.marca) LIKE 'MIKES%'` → **`Mikes`** (unifica TODAS las variantes de sabor de Mikes
    — Fresa/Lemon/Maracuya/Arandano/Apple/Mango Hot, en cualquier capitalizacion — en una sola
    marca "Mikes"; el sabor especifico no se reporta en esta vista).
  - `UPPER(v.marca) = 'CRISTAL (PERU)'` → **`Cristal`** (match EXACTO, no `LIKE 'CRISTAL%'` —
    "Cristalina" es una marca distinta y no debe caer en esta regla).
  - `UPPER(v.marca) LIKE 'CUSQUEÑA%'` → **`Cusqueña`** (unifica TODAS las variantes: Trigo,
    Malta, Negra, Quinua, Doble Malta, Red Lager, Cero Trigo, y la propia "Cusqueña" sola).
  - `UPPER(v.marca) LIKE 'CORONA%' OR UPPER(v.marca) LIKE 'CORONITA%'` → **`Corona`** (unifica
    Corona Extra/Cero/Tropical y Coronita Extra).
  - `UPPER(v.marca) = 'PILSEN CALLAO FRESH'` → **`Pilsen Callao`** (match EXACTO — "Pilsen Fresh"
    y "Pilsen Trujillo" son marcas distintas, no deben caer en esta regla).
  - **Patron a seguir para casos nuevos:** cuando el usuario pide unificar "todo lo que tenga
    [palabra] en el nombre", usar `LIKE` con esa palabra en mayusculas + `%` — pero primero
    revisar la lista completa de marcas (`SELECT DISTINCT marca ...`) para confirmar que no hay
    una marca *distinta* que tambien empiece/contenga esa palabra (como Cristal/Cristalina o
    Pilsen Callao/Pilsen Fresh) antes de aplicar un `LIKE` amplio — en esos casos usar match
    exacto (`=`) en vez de `LIKE`. Si aparece un caso similar en el futuro, confirmar con el
    usuario antes de sumarlo a esta lista — no asumir.
- **Filas sin volumen real se ocultan** (ver regla general en "Cardinalidad / filas vacias" abajo).

## Formato (pack)

- Campo: `pack` de `slv_maz_dataexperience_peru_revenue.revenue_maestro_sku`, join
  `dm_venta.material_id = revenue_maestro_sku.sku`.
- Tabla de **carga manual** (ver seccion de esa tabla en `BITACORA_TABLAS.md`) — **validar
  cobertura de join cada vez que se corre para un alcance/periodo nuevo**: revisar que
  `COALESCE(r.pack, 'Sin mapear')` no traiga volumen relevante en "Sin mapear". Validado
  2026-08-27 para las 4 gerencias de Centro Oriente: 100% de cobertura (0 HL sin mapear).
- Cardinalidad manejable (~20-24 formatos por gerencia). Mismo criterio de orden fijo que Marca.
- **Filas sin volumen real se ocultan** (ver regla general en "Cardinalidad / filas vacias" abajo).

## Pack (pack_xxx)

- Campo: `pack_xxx` de `slv_maz_dataexperience_peru_revenue.revenue_maestro_sku` (mismo join que
  Formato: `dm_venta.material_id = revenue_maestro_sku.sku`). Agregado a pedido del usuario
  2026-09-01 como septima seccion del dashboard ("Por Pack"), separada de "Por Formato".
- **Es una agrupacion mas gruesa que `pack`** (Formato): envase + rango de mililitraje
  redondeado, en vez del formato exacto. Ejemplos confirmados (2026-09-01): `pack` = "355 CAN" /
  "473 CAN" / "269 CAN" → `pack_xxx` = "CAN XXX" (los tres); `pack` = "620 RB" / "630 RB" /
  "650 RB" → `pack_xxx` = "RB 6XX"; tambien existen "NRB 3XX", "RB 3XX", "RB 1XXX", "KEG XXX",
  "Other"/"NRB Other"/"RB Other" para formatos poco comunes. Solo ~7 valores distintos en total
  (vs. ~20-24 de `pack`) — es la vista "de alto nivel" del formato/envase.
- Misma tabla de **carga manual** que Formato — **validar cobertura de join cada vez que se corre
  para un alcance/periodo nuevo**: revisar que `COALESCE(r.pack_xxx, 'Sin mapear')` no traiga
  volumen relevante en "Sin mapear". Validado 2026-09-01 para las 5 gerencias de Centro Oriente:
  100% de cobertura (0 HL sin mapear).
- Mismo criterio de orden fijo y de ocultar filas sin volumen real que Marca y Formato (ver
  "Cardinalidad / filas vacias" abajo).

## Marca x Formato (seccion cruzada)

- Agregada a pedido del usuario 2026-09-01 como octava seccion del dashboard ("Por Marca x
  Formato") — cruza Marca y Formato en una sola tabla, una fila por combinacion real con volumen
  (ej. "Pilsen Callao — 630 RB"), en vez de dos tablas separadas de una sola dimension cada una.
- Usa una query dedicada (`marcaformato_cd_categoria_mensual.sql`) que agrupa por AMBAS
  dimensiones a la vez (marca normalizada + `pack`/Formato) — no se puede armar cruzando los
  resultados de las queries de Marca y Formato por separado, esas ya vienen agregadas cada una
  a su propia dimension y perdes la combinacion real.
- **Arquitectura del template:** el indice (`IDX_MARCAFORMATO`) usa la MISMA logica de key que
  las demas secciones (`indexN`, `sumDim`) pero con 2 "dims de valor" en vez de 1 -- la key queda
  `gerencia|centro|categoria|canal|marca|formato` (canal en la posicion 3, como todos los indices
  de detalle desde que existe el filtro global de Canal -- ver esa seccion mas abajo), y el
  `dimVal` que recibe `sumDim` es el string compuesto `"marca|formato"` (se concatena antes de
  llamar a `sumDim`, que ya arma `${g}|${c}|${cat}|${canal}|${dimVal}` y matchea perfecto contra
  esa key de 6 partes). El orden fijo usa `computeSortedComboDims` (variante de
  `computeSortedDims` que toma `parts.slice(4).join("|")` en vez de `parts[4]`) — si se agrega
  OTRA seccion cruzada de 2+ dims en el futuro, reusar este mismo patron en vez de inventar uno
  nuevo.
- Cardinalidad mayor que las demas secciones (una combinacion por cada marca+formato real, no
  solo por marca o por formato) — dimensiona con un `COUNT(*)` antes de correr la query para un
  alcance nuevo, puede ser bastante mas grande que las otras 6 queries.

## Cardinalidad / filas vacias en Marca, Formato, Pack y Marca x Formato

**Regla fija (confirmada por el usuario 2026-08-31):** `computeSortedDims`/`computeSortedComboDims`
(usadas por las cuatro secciones) filtran las marcas/formatos/packs/combinaciones que no tienen
volumen real en NINGUN mes del rango mostrado (`YEAR_MIN..YEAR_MAX`) — dims con 0 HL o negativo
(ruido de devoluciones/notas de credito, o valores que solo existian fuera del rango de anios
mostrado) se excluyen de la tabla por completo, no solo se ordenan al final. El orden de las
filas visibles sigue basandose en el volumen del ultimo periodo anual, no en el historico
completo. Si se toca esta funcion, verificar que
`total_vs_marcasum`/`total_vs_packsum`/`total_vs_packxxxsum`/`total_vs_marcaformatosum` en
`verify_dashboard.js` sigan reconciliando (esos chequeos usan el indice crudo completo, no la
lista filtrada, asi que confirman que no se perdio
volumen real al ocultar filas).

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
- **Lo que hoy es marginal puede dejar de serlo — revalidar el diff headline-vs-curado en CADA
  refresh, no solo en el build inicial.** Caso real: el 2026-08-27, `CD San Benedicto I (Ate)`
  para Tarapoto y `CD Pucallpa` para Iquitos se evaluaron como ruido/marginal (0 o casi 0 HL) y
  quedaron fuera del `cd_list`. Al refrescar datos el 2026-08-29 (mismo mes, `202608`, pero con
  mas dias facturados), esos mismos cruces ya traian **2,898 HL** (Tarapoto/San Benedicto,
  Beer+Rtds) y **1,122 HL** (Iquitos/Pucallpa) — ambos **100% canal DAs**, mismo patron ya
  confirmado en el caso original de Tarapoto/CD Pucallpa. Se detecto porque el usuario comparo el
  Total del dashboard contra su propia fuente de facturacion y noto una diferencia de ~4,039 HL
  (Beer+Rtds, Direccion completa) — el dashboard mostraba 211,549 vs. 215,620 reales. Se
  confirmo el canal (100% DAs) y se agregaron ambos CD a sus respectivos `cd_list`, lo que redujo
  el diff headline-vs-curado de Tarapoto de 8.73% a 0.45% y el de Iquitos de 4.41% a 0.00%.
  **Leccion para el skill:** en un refresh de datos (no solo en el build inicial), mirar igual el
  bloque `[info] Total headline vs Total base` que imprime `verify_dashboard.js` — si algun
  porcentaje crecio de forma notoria respecto al run anterior, es señal de que el patron "canal
  DAs" se corrio a un CD nuevo o crecio en volumen, y vale la pena investigar antes de publicar
  sin mas.
- **El patron de "CD que no corresponde geograficamente" NO es exclusivo del canal DAs — ya se
  vio en 3 canales distintos.** Al refrescar el 2026-08-31 aparecieron dos casos nuevos, ninguno
  canal DAs:
  - `PE Ger P4 Pucall Hco` + `CD Iquitos`/`CD Yurimaguas`/`CD Tarapoto` (20.6 HL, canal
    **DSD OFF**): un mismo cliente real (`Naviera Oriente S.A.C.`, empresa de transporte fluvial)
    aparece con **codigos de cliente distintos por plaza** (`INO091` en Iquitos, `INO095` en
    Yurimaguas) pero factura bajo gerencia Pucallpa — logica de negocio fluvial (rutas de rio
    entre Iquitos/Yurimaguas/Pucallpa), no ruido ni DAs.
  - `PE Ger P4 Tarapoto` + `CD Chiclayo` (25.4 HL, canal **Key Accounts**): un solo cliente,
    `Plaza Vea Oriente S.A.C.` (cadena de supermercados) — cuenta nacional gestionada/distribuida
    de forma centralizada, factura bajo Tarapoto pero el CD queda en otra region.
  **Leccion:** al investigar un cruce gerencia-CD sospechoso, no asumas que el canal sera `DAs`
  solo porque los casos anteriores lo fueron — revisa el canal real (`unidad_negocio_revenue_
  volumen_meta`) y el/los cliente(s) involucrados antes de decidir si es ruido disperso (muchos
  clientes chicos, tipico de `DSD OFF` minorista mal mapeado en el maestro — ver el caso de los
  7 CD/15 POCs de Huancay Ch) o volumen real concentrado en pocos clientes grandes (cualquier
  canal: DAs, DSD OFF fluvial/multi-plaza, o Key Accounts nacional) que **si** vale la pena
  incluir en el `cd_list`.
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

## Variante "Por Cliente" en vez de "Por Canal" (gerencias tipo canal, ej. DA Jun Puc)

Cuando una gerencia es 100% un solo canal (ej. `PE Ger P4 DA Jun Puc` = 100% `DAs`), la sección
"Por Canal" no aporta nada (una sola fila con todo el volumen) — a pedido del usuario
(2026-09-03) se reemplazó por "Por Cliente" (`dm_cliente.nombre`) en un dashboard aparte,
scoped a esa sola gerencia (`da_jun_puc_dashboard.html`, no se tocó el template
multi-gerencia compartido). Arquitectura: igual que Marca/Formato/Pack (dimension dinámica,
orden fijo por volumen, filas sin volumen oculto vía `computeSortedDims`), no como Canal (lista
fija de 6 columnas) — un cliente no tiene un set fijo de valores conocido de antemano.

**Cardinalidad manejable:** 23 `cliente_id` distintos en DA Jun Puc (2025-01 a 2026-09), pero
**un mismo distribuidor real puede facturar con más de un `cliente_id`** (a veces desde CD
distintos) — mismo patrón ya documentado en la sección CD de más abajo (caso Naviera Oriente).
Agrupar por `nombre` (no por `cliente_id`) ya colapsa la mayoría de estos casos automáticamente
porque el texto es idéntico entre códigos. **Excepción confirmada:** "Inv. Globales Olarte" /
"Inversiones Globales Olarte S.A.C" / "Inversiones Globales Olarte S.A.C." son 3 variantes de
escritura del mismo cliente (4 códigos) — normalizado con
`CASE WHEN c.nombre LIKE '%Globales Olarte%' THEN 'Inversiones Globales Olarte S.A.C.' ELSE
c.nombre END`. Resultado: 23 códigos → ~12 clientes reales agrupando por nombre normalizado.
Si se repite este patrón para otra gerencia/dirección, revisar la lista de nombres distintos
antes de asumir que no hay más variantes de escritura como esta.

**Hallazgo relacionado, más importante (2026-09-03): `dm_venta.gerencia` NO es 100% retroactivo
para reasignaciones de un cliente individual, solo para la reestructuración grande de
direcciones/gerencias documentada en CLAUDE.md.** Al investigar por qué "Ucayali Beer S.A.C."
(`cliente_id` 13836158, CD Satipo) no aparecía en Ene-Mar 2026 en la sección Por Cliente, se
encontró que `v.gerencia` para ese cliente vale `PE Ger P4 Huancay Ch` hasta el mes `202603` y
recién pasa a `PE Ger P4 DA Jun Puc` desde `202604` (mes a mes, no de golpe) — mientras que
`dm_cliente.gerencia` (ficha vigente) YA dice `DA Jun Puc` para todo el histórico. Es decir, el
campo captura la gerencia **tal como estaba en el momento de cada venta** para reasignaciones
individuales de cliente, a diferencia de la reestructuración grande de 2026 donde sí se
reescribió `v.gerencia` retroactivo. Se midió el alcance de este patrón en las 5 gerencias de
Centro Oriente (2025-01 a 2026-09, `v.gerencia <> c.gerencia`): además de Ucayali Beer (36,355
HL, caso real y grande), hay 16 clientes más con mismatch pero reasignados a **otras
direcciones** (Tacna, Piura, Chiclayo Ca, Sur Chico, Puno) por menos de 175 HL combinados —
ruido marginal que confirma que la regla general de CLAUDE.md (usar `v.gerencia`, no
`c.gerencia`, para evitar traer clientes reasignados fuera de Centro Oriente) sigue siendo
correcta. **Tratamiento aplicado (a pedido del usuario):** para Ucayali Beer se reasignó el
100% del histórico a `PE Ger P4 DA Jun Puc` en las 7 queries de `da_jun_puc_dashboard.html`, con
`CASE WHEN v.cliente_id = '13836158' THEN 'PE Ger P4 DA Jun Puc' ELSE v.gerencia END` tanto en
el filtro `WHERE` como en el `SELECT`/`GROUP BY` de `gerencia` (no alcanza con solo el filtro:
si se deja `v.gerencia` sin el CASE en el SELECT, las filas de Ene-Mar quedan indexadas bajo
`PE Ger P4 Huancay Ch`, que no está en `GERENCIA_LIST` de ese dashboard, y el JS las ignora en
silencio). **Pendiente/riesgo:** el dashboard general de Centro Oriente
(`centro_oriente_dashboard.html`) NO tiene todavía este mismo override — sigue mostrando el
volumen de Ucayali Beer de Ene-Mar 2026 bajo Huancay Ch. Si se vuelve a correr ese dashboard,
confirmar con el usuario si aplica la misma reasignación (para consistencia entre ambos
dashboards) antes de publicar un refresh.

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

## Vinculacion CD -> Gerencia y acotamiento de Canal por Gerencia (agregado 2026-09-03)

Ademas del acotamiento ya existente Gerencia -> CD (el toolbar de Centro solo muestra la union de
`cd_list` de las gerencias seleccionadas, ver seccion anterior), el template implementa el sentido
**inverso** y una tercera vinculacion con Canal, a pedido del usuario ("si se selecciona 1
gerencia, abajo solo se muestren los CDs correspondientes y viceversa, lo mismo que este unido a
canal"):

- **CD -> Gerencia (`onCentroSetChange()`):** al hacer click en un boton de Centro, se recalcula
  `state.gerencias` como el conjunto de gerencias cuyo `cd_list` (`CD_DIMS[g]`) contiene ALGUNO de
  los CD actualmente seleccionados (`state.centros`) — via `CD_DIMS[g].some(c =>
  state.centros.has(c))`. Si la seleccion de CD no pertenece a ninguna gerencia (caso borde, no
  deberia pasar en la practica), cae de vuelta a todas las gerencias. Efecto: click en un CD
  exclusivo de una sola gerencia deja esa gerencia como la UNICA seleccionada; click en un CD
  compartido por 2+ gerencias (ver bug de CD compartidos arriba) selecciona esas 2+ gerencias
  juntas.
- **Por que no oscila / es estable:** el toolbar de Centro (`rebuildCentroToolbar`) SIEMPRE
  restringe los botones visibles a `unionCdDims([...state.gerencias])` — nunca se puede hacer
  click en un CD fuera del alcance de la gerencia ya seleccionada. Esto significa que un click en
  CD solo puede **angostar** la gerencia (o dejarla igual), nunca expandirla mas alla de lo que ya
  estaba disponible — no hay ciclo de retroalimentacion gerencia->CD->gerencia que crezca o
  parpadee.
- **Canal acotado por Gerencia (`computeAvailableCanales(gerCodes)`):** el toolbar de Canal ya no
  muestra siempre los 6 `CANAL_DIMS` — se filtra a los canales con volumen real (`sumCanalRow(...)
  > 0.001` HL) para la seleccion de gerencia(s) actual, sumando sobre TODOS los CD/categorias y
  TODOS los meses mostrados (no el mes actual del toolbar de Periodo, para que no cambie la lista
  de canales solo por cambiar de periodo). Se recalcula en `onGerenciaSetChange()` y en
  `onCentroSetChange()` (porque este ultimo tambien cambia `state.gerencias`).
  **Caso real (confirmado por verify_dashboard.js):** `DA Jun Puc` solo tiene volumen en el canal
  `DAs` (coherente con que es una gerencia 100% distribuidor, ver seccion "Variante Por Cliente"
  mas abajo) — al seleccionar solo esa gerencia, el toolbar de Canal se reduce a un solo boton. Las
  otras 4 gerencias tienen los 6 canales con volumen real.
- **Funciones nuevas/modificadas en el template:** `computeAvailableCanales(gerCodes)`,
  `refreshOrdersForGerencia()` (extrae el recalculo de `marcaOrder`/`formatoOrder`/`packOrder`/
  `marcaFormatoOrder` que antes vivia inline en `onGerenciaSetChange`, ahora compartido por ambos
  handlers), `onCentroSetChange()`. `rebuildCentroToolbar`/`rebuildCanalToolbar` ahora respetan el
  estado real de seleccion (`state.centros.has(c)`/`state.canales.has(c)`) en vez de asumir
  siempre-todo-activo. El listener de `seg-centro` llama a `onCentroSetChange()` en vez de
  `renderAll()` directo.
- **Cobertura en `verify_dashboard.js`:** stress-test que recorre cada gerencia seleccionando su
  primer CD via `onCentroSetChange()` (sin excepciones); print informativo de canales disponibles
  por gerencia; chequeo de correctitud dedicado `CD exclusivo -> auto-selecciona solo su gerencia`
  que, para cada gerencia, busca un CD exclusivo suyo (no compartido con otra gerencia) y verifica
  que seleccionarlo deja `state.gerencias` como exactamente `{esa gerencia}`. **Gotcha del arnes de
  test:** `state` esta declarado `const state = {...}` dentro del script del dashboard ejecutado
  via `vm.runInContext` — no se vuelve una propiedad de `sandbox` visible desde Node (a diferencia
  de `var`/asignaciones `this.x = ...`). Para leerlo desde Node hay que hacer, dentro del MISMO
  `vm.runInContext`, algo como `this.__RESULT_GERENCIAS__ = [...state.gerencias];` y despues leer
  `sandbox.__RESULT_GERENCIAS__` en Node — nunca `sandbox.state` directo (mismo patron ya usado
  para `__VERIFY_RESULT__`/`__CD_OWNER_CHECK__`).

## Gerencia y CD como selección única tipo "radio" (agregado 2026-09-03, tarde)

A pedido del usuario ("alineemos el estilo visual radio / color-coded", comparando contra el
artifact "Evolución de Brand Distribution"), **Gerencia y CD dejaron de ser multi-select** y
pasaron a ser de **selección única real**, con un punto de color por gerencia — esto reemplaza
todo lo descrito en la seccion anterior sobre Gerencia multi-select y CD multi-select (esa seccion
queda como historia/contexto del bug de CD compartidos, que sigue siendo relevante para el
`sumBase`/`sumDim`, pero el modelo de seleccion de arriba ya no aplica). **Categoría y Canal siguen
siendo multi-select** (checkboxes que suman) — el usuario solo pidio alinear Gerencia/CD, no todo
el toolbar.

- **"Total Dirección" ahora vive DENTRO del segset de Gerencia** (primera opcion, `data-v="ALL"`),
  no como un grupo de toolbar separado (`seg-direccion`) como antes. `rebuildDireccionToolbar()`
  y el listener de `#seg-direccion` se eliminaron.
- **`state.gerencias`** sigue siendo un `Set` internamente (para no tocar `sumBase`/`sumDim`, que
  ya aceptaban arrays), pero el toolbar ahora SOLO puede dejarlo en dos formas: `Set` con TODOS
  los codigos (Total Dirección) o `Set` con **exactamente 1** codigo. Click en una gerencia
  puntual REEMPLAZA el Set (`new Set([v])`), no lo togglea.
- **`state.centros`** cambio de semantica: **vacio = "todos los CD de la gerencia actual"** (sin
  necesidad de un boton "Todos" explicito — ningun botón de CD queda resaltado en ese estado), y
  con exactamente 1 elemento = narrowing a ese CD puntual. Nueva funcion `activeCentros(gerCodes)`
  centraliza esta logica (`unionCdDims(gerCodes)` si vacio, filtrado si no) — TODO el codigo que
  antes leia `[...state.centros]` directo (`renderSection`, `renderAll`, `metaLabel`) ahora pasa
  por esta funcion. Click en el UNICO CD ya activo lo deselecciona (vuelve a "todos"); click en
  otro CD reemplaza la seleccion.
- **Color por gerencia:** nuevas variables CSS `--ger-total`/`--ger-dajunpuc`/`--ger-huancay`/
  `--ger-iquitos`/`--ger-pucallpa`/`--ger-tarapoto` (con variantes dark-mode), mapeadas en JS via
  `GERENCIA_COLOR` (por `code`). Cada boton de Gerencia lleva `<span class="dot">` con
  `style="--dot:..."`. Los botones de CD usan el color de su gerencia **dominante**, no de la
  gerencia actualmente seleccionada (ver punto siguiente).
- **`CD_DOMINANT_GERENCIA` (nuevo, NO confundir con `CD_DIMS`):** mapeo **1:1** CD→gerencia,
  reusando el mismo criterio ">98% del volumen real" ya documentado en `CLAUDE.md` para el
  artifact de Brand Distribution (Pucall Hco: Huánuco/Tingo María/Pucallpa; Huancay Ch:
  Huancavelica/Huancayo/Satipo/Chanchamayo; Iquitos: Iquitos; Tarapoto: San
  Benedicto/Moyobamba/Tarapoto/Yurimaguas/Motupe/Chiclayo — estos 2 ultimos no estaban en la
  lista original de `CLAUDE.md` por ser CDs agregados despues, pero son exclusivos de Tarapoto en
  `cd_list` asi que no hay ambiguedad; DA Jun Puc: ninguno). Se usa **solo para navegacion** (a
  que gerencia saltar al elegir un CD), nunca para sumar/filtrar datos — eso lo sigue haciendo
  `CD_DIMS` (el `cd_list` curado, muchos-a-muchos, real).
- **`onCentroSetChange()` no siempre usa el mapeo dominante.** Si el CD elegido ya pertenece al
  `cd_list` PROPIO de la gerencia actualmente seleccionada (`CD_DIMS[currentGer].includes(cd)`),
  la gerencia **NO cambia** — evita el salto sorpresivo de estar mirando el detalle de una
  gerencia y que un click en un CD válido para ELLA te mande a otra. Ejemplo real: "CD Pucallpa"
  es volumen real tanto de Iquitos como de Pucall Hco (dominante); si el usuario está en Iquitos y
  hace click en "CD Pucallpa" (aparece en su propio toolbar porque es real), se queda en Iquitos.
  Solo se usa `CD_DOMINANT_GERENCIA` cuando el CD NO pertenece a la gerencia actual (típicamente
  viniendo de "Total Dirección", donde el toolbar de CD muestra la unión de los 14).
- **Deseleccionar el único CD activo (toggle-off) vuelve a "Total Dirección"** (no hay forma de
  "quedarse en la gerencia actual sin CD" tras haber elegido uno puntual y sacarlo — se resetea
  al estado inicial completo). Simplificacion deliberada, no hay tracking de "gerencia previa".
- **Cobertura en `verify_dashboard.js`:** el chequeo `CD exclusivo -> auto-selecciona solo su
  gerencia` (ya existente) sigue validando el salto DESDE Total Dirección. Nuevo chequeo `CD
  compartido dentro de la gerencia actual -> NO cambia de gerencia`: busca, para cada gerencia,
  un CD de su propio `cd_list` cuyo `CD_DOMINANT_GERENCIA` sea DISTINTO (un CD "prestado" de
  verdad), selecciona esa gerencia sola, hace click en ese CD, y verifica que la gerencia no
  cambió. Encuentra casos reales para DA Jun Puc/CD Pucallpa, Iquitos/CD Pucallpa, Pucall
  Hco/CD Iquitos y Tarapoto/CD Pucallpa — cubre las 4 direcciones del bug de CD compartidos con
  el nuevo modelo de seleccion unica.
- **Decisión de alcance visual:** se mantuvo el look de "control segmentado agrupado" (mismo
  contenedor con borde compartido que Periodo/Categoría/Canal) en vez de replicar el look de
  "chips/píldoras individuales con borde propio" del artifact Brand Distribution — para no romper
  la consistencia visual del resto del toolbar. Lo que se alineó fue el **comportamiento** (radio
  en vez de multi-select) y el **punto de color por gerencia**, no la forma exacta del botón.

## Filtros base (siempre presentes)

- `v.indicadores_comerciales = 1` (KPIs comerciales oficiales).
- **REGLA CORREGIDA (2026-09-04, invierte la guia anterior de este parrafo — las 7 plantillas SQL
  de este skill todavia usan `v.gerencia` y quedan pendientes de reescribir):** filtrar/agrupar
  por `c.gerencia` (de **`dm_cliente`**, join `v.cliente_id = c.cliente_id`), no `v.gerencia`. Un
  cliente reasignado de gerencia a mitad de año (caso real: Ucayali Beer, Huancay Ch → DA Jun Puc
  en abril 2026) queda partido entre dos gerencias en `dm_venta.gerencia` segun el mes de la
  venta — `dm_cliente` es una foto vigente y atribuye todo su historico a la gerencia actual de
  forma consistente. Ver detalle en `CLAUDE.md` → "Alcance tipico" y `BITACORA_TABLAS.md` →
  `dm_cliente`. Antes de volver a correr este skill para un alcance nuevo, migrar las 7 queries de
  `assets/querys/` a este join.
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
  footer/narrativa, **y tambien el calculo de `complete` en `buildQuarterPeriods`** (ver bug
  real abajo).
- **Bug real encontrado y corregido (2026-09-02):** al arrancar un mes nuevo (ej. `LATEST_MONTH`
  pasa de 8 a 9 en un refresh), el trimestre que contiene ese mes (`Q3` = Jul-Set) se marcaba
  como `complete:true` en la vista Trimestral apenas los 3 meses entraban en el rango mostrado
  (`ms.length===3`), sin chequear si el mes en curso (el ultimo del trimestre) todavia estaba
  parcial. Esto hacia que la badge "parcial" NO apareciera en `Q3'26` con Septiembre recien
  arrancado (2 dias de datos) y que `lastCompleteQuarter()` lo eligiera como "ultimo trimestre
  completo" en vez de `Q2'26`. Se corrigio agregando el chequeo `endsOnPartialLatest` en
  `buildQuarterPeriods` (`assets/dashboard_template.html`): un trimestre con sus 3 meses en
  rango NO es `complete` si `LATEST_MONTH_IS_PARTIAL` es `true` y ese mes cae dentro del
  trimestre. Si se agrega otra dimension temporal derivada de `LATEST_MONTH` en el futuro,
  revisar que tambien considere `LATEST_MONTH_IS_PARTIAL`, no solo si el mes "entra en rango".
- **Regla fija (confirmada por el usuario 2026-09-03): el resumen Anual/YTD SIEMPRE corta en el
  ultimo mes CERRADO, nunca en un mes parcial, aunque Mensual/Trimestral SI muestren ese mes
  parcial como columna propia.** Coincide con la definicion de YTD de `CLAUDE.md` ("a mes
  cerrado, no incluye el mes en curso"). Implementado con `YTD_MAX_MONTH = LATEST_MONTH_IS_PARTIAL
  ? LATEST_MONTH-1 : LATEST_MONTH` en `buildYearPeriods` (`assets/dashboard_template.html`) --
  `PERIODS.year`/`PERIODS.ytd` usan `YTD_MAX_MONTH` como techo, mientras que
  `buildMonthPeriods`/`buildQuarterPeriods` siguen usando `LATEST_MONTH` sin recortar (por eso
  Septiembre parcial aparece en Mensual/Trimestral pero el "2026 YTD" se queda en Agosto). Este
  comportamiento es automatico en cada refresh -- no hace falta tocar `run_config.json` para
  esto, solo mantener `latest_month`/`latest_month_is_partial` correctos (ver arriba).

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
