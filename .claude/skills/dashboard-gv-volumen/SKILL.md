---
name: dashboard-gv-volumen
description: Arma el dashboard interactivo de Volumen (HL) por gerencia de ventas (GV) que ya se construyo para las 5 gerencias de Centro Oriente — un selector de Gerencia y CD de SELECCIÓN ÚNICA tipo radio (con punto de color por gerencia, vinculados entre sí: elegir un CD selecciona su gerencia y viceversa; "Total Dirección" como primera opción de Gerencia), mensual/trimestral/anual comparado vs. año anterior, con filtros globales multi-select de Categoría (Beer/Rtds/Nabs) y Canal (DSD OFF/DSD ON/WHL/EVE/DAS/KA, acotado por la gerencia seleccionada), y cortes por Total, Categoría, CD, Canal, Marca, Pack, Formato y Marca × Formato. Usar SIEMPRE que el usuario pida este mismo tipo de dashboard para otra dirección/otro conjunto de gerencias, otro periodo, o pida explícitamente "el dashboard GV volumen" / "el mismo análisis de Centro Oriente" — no reconstruir el análisis desde cero a mano cuando este skill ya tiene la plantilla, las queries y el validador armados.
---

# Dashboard GV Volumen

Reproduce, para cualquier conjunto de gerencias (típicamente todas las de una dirección), el
dashboard de Volumen (HL) que se construyó originalmente para las 5 gerencias de Centro Oriente
(4 geográficas + 1 de canal, DA Jun Puc): un Artifact HTML con un selector de **Gerencia de
selección única tipo radio** (con "Total Dirección" como primera opción del mismo segset — con
esa activa se ve el total de la Dirección completa; eligiendo una gerencia puntual se aísla solo
esa), vistas Mensual/Trimestral/Anual, y 8 secciones (Total, Categoría, CD, Canal, Marca, Pack,
Formato, Marca × Formato) — con filtros multi-select de **Categoría** y **Canal** (Canal se acota
a los canales con volumen real de la gerencia elegida), y un filtro de **Centro (CD)** también de
selección única y vinculado bidireccionalmente con Gerencia: elegir un CD selecciona
automáticamente su gerencia (si el CD es "propio" de la gerencia ya elegida, no salta; si no,
salta a su gerencia dominante — ver `references/reglas_negocio.md`), y elegir una gerencia acota
qué CD se ofrecen. Todos los filtros recalculan TODAS las secciones simultáneamente.

**No reescribas el HTML/JS a mano.** El diseño (paleta, tipografía, layout) y la lógica
(agregación con comparación justa de periodos parciales, filtros cruzados CD×Categoría,
reconciliación de totales entre secciones) ya están resueltos en
`assets/dashboard_template.html`. Tu trabajo al correr este skill es: reunir los parámetros de
las gerencias nuevas, correr las 7 consultas SQL, inyectar los datos, validar, y publicar.

**Solo volumen (HL), no rentabilidad (NR).** Esta versión del dashboard quitó NR a pedido del
usuario — si en el futuro piden agregar NR de vuelta, es un cambio de alcance del template (no
asumas que hay que revivirlo solo).

## Antes de empezar: reglas de negocio fijas

Lee **`references/reglas_negocio.md`** — define cómo se arman las categorías (Beer/Rtds/Nabs,
exclusión de San Mateo), el mapeo de canal (WHL/EVE/DAS/KA, fold de "High End" en DSD ON), el
proceso para confirmar el CD_LIST de cada gerencia (incluyendo el patrón "canal DAs" que puede
inflar un CD de una gerencia vecina — ver el caso Tarapoto/CD Pucallpa), y las reglas de Marca,
Formato y Pack. Estas reglas ya están horneadas en las plantillas SQL y en el template — no las
repitas ni las reinventes, solo tenlas presentes para explicar el dashboard si el usuario
pregunta.

## Paso a paso

### 0. Reunir los parámetros del run

| Parámetro | Cómo conseguirlo |
|---|---|
| `gerencias` (lista) | Código transaccional de `dm_venta.gerencia` para cada una (ver `BITACORA_TABLAS.md`). Si alguna es de otra naturaleza (ej. un canal tipo "DA" — Distribuidor Autorizado, no una zona geográfica), preguntale al usuario si merece un `cd_list` distinto (probablemente "incluir todos los CD que aparezcan", no una lista curada excluyendo marginales) antes de sumarla al run — ver el caso `PE Ger P4 DA Jun Puc` en `references/reglas_negocio.md`, que sí terminó incluida (a pedido del usuario) pero con ese criterio distinto. |
| `direccion_label` | Texto que se muestra cuando **todas** las gerencias del run están seleccionadas a la vez (ej. "Dirección Centro Oriente"). |
| `year_min` / `year_max` | Ventana de años a **mostrar**. El año `year_min - 1` nunca se muestra como columna propia, solo como base LY del primer año mostrado — necesitás datos SQL desde `year_min - 1`, no desde `year_min`. Para mostrar 2 años (ej. 2025 y 2026): `year_min=2025, year_max=2026`. Para mostrar **un solo año** (ej. solo 2026, con 2025 100% oculto salvo como base de la variación % y nominal vs LY): `year_min=2026, year_max=2026` — el template ya soporta `year_min===year_max` (colapsa el texto del encabezado a un solo año en vez de un rango, sin tocar el HTML). No hace falta volver a correr las 5 queries SQL para este cambio si ya tenías los datos del año anterior cargados — alcanza con ajustar `year_min` en `run_config.json` y re-correr `inject_data.py` + `verify_dashboard.js`. |
| `latest_month` | Mes más reciente con datos reales dentro de `year_max` — correlo: `SELECT max(mes) FROM dm_venta WHERE mes >= '{year_max}01'`. **No asumas que es el mes calendario actual.** |
| `latest_month_is_partial` | `true` si ese mes está a medio cerrar. |
| `cd_list` por gerencia | Ver Paso 1 — **nunca lo decidas vos solo mirando volumen**, confirmalo con el usuario. |

### 1. Explorar y confirmar los CD reales de cada gerencia

Corré `assets/querys/explorar_centros.sql` (reemplazando `{{GERENCIA_IN_LIST}}` con todas las
gerencias del run de una vez — es más rápido que una query por gerencia) y mostrale al usuario
la tabla resultante (gerencia, centro, filas, hl). **No asumas que un CD chico es marginal ni
que un CD grande es real** — hay un patrón real y ya documentado (ver
`references/reglas_negocio.md` → "Patrón canal DAs"): un CD puede aparecer con volumen NO
trivial en una gerencia donde geográficamente no debería estar, porque los Distribuidores
Autorizados (canal `DAs`) se abastecen del CD más grande/cercano sin importar bajo qué gerencia
comercial facturan. Si ves un CD así, corré
`assets/querys/explorar_cd_sospechoso_por_canal.sql` para confirmar si es 100% canal `DAs` antes
de preguntarle al usuario qué hacer (excluirlo, incluirlo, o algo intermedio — fue una decisión
suya en Centro Oriente, no la des por sentada para otra dirección).

### 2. Correr las 7 consultas en Databricks

Usá el skill `databricks-query`. Cada una de las 7 plantillas en `assets/querys/` (`gerencia_
mensual`, `base_cd_categoria_mensual`, `canal_cd_categoria_mensual`, `marca_cd_categoria_
mensual`, `formato_cd_categoria_mensual`, `pack_cd_categoria_mensual`,
`marcaformato_cd_categoria_mensual`) se corre **una sola vez**, cubriendo TODAS las gerencias del
run y el rango completo `{year_min-1}01` a `{year_max}{latest_month}` en una pasada — no hace
falta separar el año base ni correr una query por gerencia. `marcaformato_cd_categoria_mensual`
cruza 2 dimensiones a la vez (marca + formato) y por eso puede tener bastante más filas que las
demás — dimensioná con un `COUNT(*)` antes de correrla para un alcance nuevo.

Reemplazá `{{GERENCIA_IN_LIST}}` (códigos entre comillas separados por coma), `{{MES_DESDE}}`/
`{{MES_HASTA}}`, y `{{CD_IN_LIST}}` (donde aplique — es la **unión** de los `cd_list` de TODAS
las gerencias del run, no hace falta separar por gerencia porque cada fila del resultado ya
viene etiquetada con su propia `gerencia` + `centro`). Guardá los `.sql` en `querys/` en la raíz
del proyecto (para poder auditar/rerun después) y corré con `run_query.sh --file`.

`formato_cd_categoria_mensual.sql` y `pack_cd_categoria_mensual.sql` hacen join a
`revenue_maestro_sku` (carga manual) — revisá que la columna `pack`/`pack_xxx = 'Sin mapear'` no
traiga volumen relevante; si lo trae, avisale al usuario antes de confiar en la sección
Formato/Pack (ver `references/reglas_negocio.md`). `pack_xxx` es una agrupación más gruesa que
`pack` (envase + rango de mililitraje redondeado, ej. "RB 6XX", en vez del formato exacto).

**Todas las plantillas EXCEPTO `gerencia_mensual` y `canal_cd_categoria_mensual` llevan
`canal_meta` (`COALESCE(c.unidad_negocio_revenue_volumen_meta, 'Sin clasificar')`) como columna
extra**, para que el filtro global de Canal del toolbar pueda recalcular Total/Categoría/CD/
Marca/Pack/Formato/Marca×Formato — no solo la sección "Por Canal". Si agregás una plantilla
nueva que deba responder a ese filtro, sumale `canal_meta` con el mismo `COALESCE` en el
`SELECT` y el `GROUP BY` (ver `references/reglas_negocio.md` → "Filtro global de Canal" para el
detalle de por qué va en esa posición exacta de la key).

### 3. Validar volumetría antes de seguir

Revisá que las 5 consultas no vinieron vacías y que los totales tienen sentido (compará
`gerencia_mensual` vs. la suma de `base_cd_categoria_mensual` para un mes/gerencia, por
ejemplo — aunque esto ya lo hace `verify_dashboard.js` de forma exhaustiva en el Paso 5, una
mirada rápida acá te avisa antes de armar el HTML si algo salió mal en la query misma).

**Aunque sea un refresh de datos sobre gerencias ya confirmadas (no un run nuevo), no te saltees
el chequeo `[info] Total headline vs Total base` de `verify_dashboard.js` en el Paso 6.** El
patrón "canal DAs" (ver `references/reglas_negocio.md`) no es estático: un CD que hoy es ruido
marginal para una gerencia puede volverse volumen real de un mes a otro (caso real 2026-08-29:
Tarapoto/CD San Benedicto I (Ate) e Iquitos/CD Pucallpa pasaron de ~0 HL a >1,000 HL en dos días
de diferencia entre dos runs del mismo mes). Si algún % headline-vs-curado subió notoriamente
respecto al run anterior, investigá con `explorar_cd_sospechoso_por_canal.sql` antes de publicar
— no asumas que el `cd_list` ya confirmado sigue siendo correcto para siempre.

### 4. Armar `run_config.json`

Copiá `assets/run_config.example.json` y completá: los parámetros del Paso 0, un objeto por
gerencia con su `code`/`label`/`cd_list`/`cd_note` (el `cd_note` es el texto que se muestra en
la sección "Por CD" — contá ahí cualquier decisión no obvia, como el caso Tarapoto/CD Pucallpa),
y apuntá cada `raw_files.RAW_*` al `.json` que guardó cada consulta del Paso 2.

### 5. Inyectar los datos en el template

```bash
python .claude/skills/dashboard-gv-volumen/scripts/inject_data.py --config run_config.json --out <nombre>_dashboard.html
```

Reemplaza los 7 bloques `RAW_*`, los objetos `GERENCIA_LIST`/`CD_DIMS`/`CD_NOTE`, `DIRECCION_
LABEL`, y los placeholders de texto (`{{EYEBROW_TEXT}}`, `{{PAGE_TITLE_TAG}}`, etc.). Si falta
un placeholder o un `raw_files`, el script corta con error explicando cuál.

### 6. Validar el HTML generado (obligatorio antes de publicar)

```bash
node .claude/skills/dashboard-gv-volumen/scripts/verify_dashboard.js <nombre>_dashboard.html --quiet
```

`--quiet` suprime el bloque `[info]` puramente descriptivo (dims por gerencia, periodos,
canales disponibles — estable entre refreshes, no aporta nada nuevo cada vez). **No suprime**
las líneas OK/FAIL de cada chequeo ni el bloque `[info] Total headline vs Total base` — ese
seguí revisándolo siempre, con o sin `--quiet` (ver más abajo por qué). Sacá `--quiet` si querés
ver también los conteos de dims/periodos/canales (por ejemplo la primera vez que corrés el skill
para gerencias nuevas, para tener una foto completa).

Para **cada gerencia** y **cada mes** del rango, reconcilia: Total == suma de categorías ==
suma de CD == suma de canales == suma de marcas == suma de formatos == suma de packs == suma de
combinaciones marca×formato, y ADEMÁS que el filtro global de Canal (sumando por el array de
canales seleccionados) coincida con la sección "Por Canal" (que lee `IDX_CANAL` directo, sin
array). **El chequeo más
importante del set** es el #6 (multi-gerencia): con TODAS las gerencias + la unión de CD
seleccionadas a la vez, el Total tiene que ser EXACTAMENTE igual a la suma de cada gerencia
calculada por separado con su propio `cd_list` — si el filtro de Centro (que muestra la unión de
CD de todas las gerencias seleccionadas) no está bien acotado por gerencia dentro de la lógica
de agregación, un CD deliberadamente excluido para una gerencia puede "colarse" de vuelta cuando
otra gerencia seleccionada SÍ tiene ese mismo nombre de CD en su propio `cd_list` — ver el bug
real que esto detectó (caso Tarapoto/CD San Benedicto+Ate vs. DA Jun Puc) en
`references/reglas_negocio.md`. El script también corre distintas combinaciones de Gerencia
(todas, una sola, un subconjunto) combinadas con Categoría/Centro/Periodo, y dos chequeos
dedicados a la vinculación CD↔Gerencia de selección única (`CD exclusivo -> auto-selecciona solo
su gerencia` y `CD compartido dentro de la gerencia actual -> NO cambia de gerencia`), y confirma
que nada tira excepción. Si imprime `FAIL` en algo, **no publiques**.

El script también imprime, por gerencia, la diferencia entre el total "headline" (sin
restricción de CD) y el total "curado" (solo los CD del `cd_list`) — es normal que haya una
diferencia chica (CD genuinamente marginales quedaron afuera); si la diferencia es grande
revisá si te faltó confirmar algún CD con el usuario en el Paso 1.

### 7. Publicar como Artifact

Usá la tool `Artifact` (`action: publish`) con el HTML validado. Favicon 🍺 (consistente con el
resto de dashboards del proyecto). Si el usuario ya tenía un dashboard de esta familia publicado
y esto es una actualización/expansión de ese mismo análisis (no un dashboard nuevo y
desconectado), reutilizá el mismo `file_path` de esa conversación para conservar la URL —
preguntale si no estás seguro.

## Si el usuario pide algo que el template no cubre todavía

El template fue creciendo turno a turno (empezó como un dashboard de una sola gerencia con HL y
NR; después se agregó el filtro de categoría, después se expandió a multi-gerencia con selector
single-select + filtro global de CD, se sacó NR, se agregaron Marca y Formato, el selector de
Gerencia pasó a multi-select para poder ver la Dirección completa, se agregó Pack, después Marca
× Formato, después un filtro global de Canal — que obligó a agregar `canal_meta` a casi todas las
plantillas SQL, ver arriba — y finalmente Gerencia y CD volvieron a ser de selección única, ahora
estilo radio con punto de color por gerencia y vinculados entre sí, alineados al estilo del
artifact "Evolución de Brand Distribution"). Si piden algo que el template de hoy no tiene, dos
caminos:

1. **Es una preferencia de este run puntual** (ej. otro rango de años, otras gerencias, otro
   orden de columnas) → resolvelo con los placeholders/`run_config.json`, no toques el template.
2. **Es una mejora que probablemente sirva para cualquier dirección/gerencia** (ej. otro corte,
   traer de vuelta NR, otro estilo de tabla) → aplicalo sobre
   `assets/dashboard_template.html`, actualizá las 7 plantillas SQL si el cambio requiere un
   campo/join nuevo, y actualizá este `SKILL.md`/`reglas_negocio.md` si cambia el contrato de
   placeholders o las reglas de negocio. Volvé a correr `verify_dashboard.js` (y agregale
   chequeos nuevos si la mejora introduce una dimensión/seccion nueva) antes de dar por
   terminado el cambio.
