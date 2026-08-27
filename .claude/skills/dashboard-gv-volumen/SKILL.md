---
name: dashboard-gv-volumen
description: Arma el dashboard interactivo de Volumen (HL) por gerencia de ventas (GV) que ya se construyo para las 5 gerencias de Centro Oriente — un selector MULTI-SELECT de Gerencia (con todas marcadas se ve el total de la Dirección completa), mensual/trimestral/anual comparado vs. año anterior, con filtros globales multi-select de Categoría (Beer/Rtds/Nabs) y Centro de Distribución (CD), y cortes por Total, Categoría, CD, Canal, Marca y Formato. Usar SIEMPRE que el usuario pida este mismo tipo de dashboard para otra dirección/otro conjunto de gerencias, otro periodo, o pida explícitamente "el dashboard GV volumen" / "el mismo análisis de Centro Oriente" — no reconstruir el análisis desde cero a mano cuando este skill ya tiene la plantilla, las queries y el validador armados.
---

# Dashboard GV Volumen

Reproduce, para cualquier conjunto de gerencias (típicamente todas las de una dirección), el
dashboard de Volumen (HL) que se construyó originalmente para las 5 gerencias de Centro Oriente
(4 geográficas + 1 de canal, DA Jun Puc): un Artifact HTML con un selector **multi-select de
Gerencia** (con todas marcadas se ve el total de la Dirección completa; desmarcando se aíslan
una o varias gerencias puntuales), highlights ejecutivos que responden a esa selección, vistas
Mensual/Trimestral/Anual, y 6 secciones (Total, Categoría, CD, Canal, Marca, Formato) — con
filtros multi-select de **Categoría** y **Centro (CD)** que recalculan TODAS las secciones
simultáneamente, para cualquier combinación de gerencias seleccionadas.

**No reescribas el HTML/JS a mano.** El diseño (paleta, tipografía, layout) y la lógica
(agregación con comparación justa de periodos parciales, filtros cruzados CD×Categoría,
reconciliación de totales entre secciones) ya están resueltos en
`assets/dashboard_template.html`. Tu trabajo al correr este skill es: reunir los parámetros de
las gerencias nuevas, correr las 5 consultas SQL, inyectar los datos, validar, y publicar.

**Solo volumen (HL), no rentabilidad (NR).** Esta versión del dashboard quitó NR a pedido del
usuario — si en el futuro piden agregar NR de vuelta, es un cambio de alcance del template (no
asumas que hay que revivirlo solo).

## Antes de empezar: reglas de negocio fijas

Lee **`references/reglas_negocio.md`** — define cómo se arman las categorías (Beer/Rtds/Nabs,
exclusión de San Mateo), el mapeo de canal (WHL/EVE/DAS/KA, fold de "High End" en DSD ON), el
proceso para confirmar el CD_LIST de cada gerencia (incluyendo el patrón "canal DAs" que puede
inflar un CD de una gerencia vecina — ver el caso Tarapoto/CD Pucallpa), y las reglas de Marca y
Formato. Estas reglas ya están horneadas en las plantillas SQL y en el template — no las
repitas ni las reinventes, solo tenlas presentes para explicar el dashboard si el usuario
pregunta.

## Paso a paso

### 0. Reunir los parámetros del run

| Parámetro | Cómo conseguirlo |
|---|---|
| `gerencias` (lista) | Código transaccional de `dm_venta.gerencia` para cada una (ver `BITACORA_TABLAS.md`). Si alguna es de otra naturaleza (ej. un canal tipo "DA" — Distribuidor Autorizado, no una zona geográfica), preguntale al usuario si merece un `cd_list` distinto (probablemente "incluir todos los CD que aparezcan", no una lista curada excluyendo marginales) antes de sumarla al run — ver el caso `PE Ger P4 DA Jun Puc` en `references/reglas_negocio.md`, que sí terminó incluida (a pedido del usuario) pero con ese criterio distinto. |
| `direccion_label` | Texto que se muestra cuando **todas** las gerencias del run están seleccionadas a la vez (ej. "Dirección Centro Oriente"). |
| `year_min` / `year_max` | Ventana de años a mostrar (ej. 2025/2026 — el patrón validado es NO mostrar el año más viejo como columna propia, pero SÍ usarlo como base LY del primer año mostrado; necesitás datos desde `year_min - 1`). |
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

### 2. Correr las 5 consultas en Databricks

Usá el skill `databricks-query`. Cada una de las 5 plantillas en `assets/querys/` (`gerencia_
mensual`, `base_cd_categoria_mensual`, `canal_cd_categoria_mensual`, `marca_cd_categoria_
mensual`, `formato_cd_categoria_mensual`) se corre **una sola vez**, cubriendo TODAS las
gerencias del run y el rango completo `{year_min-1}01` a `{year_max}{latest_month}` en una
pasada — no hace falta separar el año base ni correr una query por gerencia.

Reemplazá `{{GERENCIA_IN_LIST}}` (códigos entre comillas separados por coma), `{{MES_DESDE}}`/
`{{MES_HASTA}}`, y `{{CD_IN_LIST}}` (donde aplique — es la **unión** de los `cd_list` de TODAS
las gerencias del run, no hace falta separar por gerencia porque cada fila del resultado ya
viene etiquetada con su propia `gerencia` + `centro`). Guardá los `.sql` en `querys/` en la raíz
del proyecto (para poder auditar/rerun después) y corré con `run_query.sh --file`.

`formato_cd_categoria_mensual.sql` hace join a `revenue_maestro_sku` (carga manual) — revisá
que la columna `pack = 'Sin mapear'` no traiga volumen relevante; si lo trae, avisale al usuario
antes de confiar en la sección Formato (ver `references/reglas_negocio.md`).

### 3. Validar volumetría antes de seguir

Revisá que las 5 consultas no vinieron vacías y que los totales tienen sentido (compará
`gerencia_mensual` vs. la suma de `base_cd_categoria_mensual` para un mes/gerencia, por
ejemplo — aunque esto ya lo hace `verify_dashboard.js` de forma exhaustiva en el Paso 5, una
mirada rápida acá te avisa antes de armar el HTML si algo salió mal en la query misma).

### 4. Armar `run_config.json`

Copiá `assets/run_config.example.json` y completá: los parámetros del Paso 0, un objeto por
gerencia con su `code`/`label`/`cd_list`/`cd_note` (el `cd_note` es el texto que se muestra en
la sección "Por CD" — contá ahí cualquier decisión no obvia, como el caso Tarapoto/CD Pucallpa),
y apuntá cada `raw_files.RAW_*` al `.json` que guardó cada consulta del Paso 2.

### 5. Inyectar los datos en el template

```bash
python .claude/skills/dashboard-gv-volumen/scripts/inject_data.py --config run_config.json --out <nombre>_dashboard.html
```

Reemplaza los 5 bloques `RAW_*`, los objetos `GERENCIA_LIST`/`CD_DIMS`/`CD_NOTE`, `DIRECCION_
LABEL`, y los placeholders de texto (`{{EYEBROW_TEXT}}`, `{{PAGE_TITLE_TAG}}`, etc.). Si falta
un placeholder o un `raw_files`, el script corta con error explicando cuál.

### 6. Validar el HTML generado (obligatorio antes de publicar)

```bash
node .claude/skills/dashboard-gv-volumen/scripts/verify_dashboard.js <nombre>_dashboard.html
```

Para **cada gerencia** y **cada mes** del rango, reconcilia: Total == suma de categorías ==
suma de CD == suma de canales == suma de marcas == suma de formatos. **El chequeo más
importante del set** es el #6 (multi-gerencia): con TODAS las gerencias + la unión de CD
seleccionadas a la vez, el Total tiene que ser EXACTAMENTE igual a la suma de cada gerencia
calculada por separado con su propio `cd_list` — si el filtro de Centro (que muestra la unión de
CD de todas las gerencias seleccionadas) no está bien acotado por gerencia dentro de la lógica
de agregación, un CD deliberadamente excluido para una gerencia puede "colarse" de vuelta cuando
otra gerencia seleccionada SÍ tiene ese mismo nombre de CD en su propio `cd_list` — ver el bug
real que esto detectó (caso Tarapoto/CD San Benedicto+Ate vs. DA Jun Puc) en
`references/reglas_negocio.md`. El script también corre el toggle multi-select de Gerencia
(todas, una sola, un subconjunto) combinado con Categoría/Centro/Periodo y confirma que no tira
excepción. Si imprime `FAIL` en algo, **no publiques**.

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
single-select + filtro global de CD, se sacó NR, se agregaron Marca y Formato, y finalmente el
selector de Gerencia pasó a multi-select para poder ver la Dirección completa). Si piden algo
que el template de hoy no tiene, dos caminos:

1. **Es una preferencia de este run puntual** (ej. otro rango de años, otras gerencias, otro
   orden de columnas) → resolvelo con los placeholders/`run_config.json`, no toques el template.
2. **Es una mejora que probablemente sirva para cualquier dirección/gerencia** (ej. otro corte,
   traer de vuelta NR, otro estilo de tabla) → aplicalo sobre
   `assets/dashboard_template.html`, actualizá las 5 plantillas SQL si el cambio requiere un
   campo/join nuevo, y actualizá este `SKILL.md`/`reglas_negocio.md` si cambia el contrato de
   placeholders o las reglas de negocio. Volvé a correr `verify_dashboard.js` (y agregale
   chequeos nuevos si la mejora introduce una dimensión/seccion nueva) antes de dar por
   terminado el cambio.
