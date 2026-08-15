---
name: databricks-query
description: Conecta a un Databricks SQL Warehouse y ejecuta consultas SQL usando curl (sin Python/Node), leyendo credenciales desde el .env del proyecto. Usar cuando el usuario pida correr una consulta SQL contra Databricks, traer datos de tablas slv_maz_* / dm_venta / dm_cliente / dm_material, o pregunte por resultados de una query en Databricks.
---

# Databricks Query

Ejecuta SQL contra un Databricks SQL Warehouse via la Statement Execution API (REST),
usando solo `curl` (no requiere Python, Node ni jq — ninguno esta instalado en esta maquina).

## Credenciales

Se leen automaticamente desde `.env` en la raiz del proyecto:

- `DATABRICKS_SERVER_HOSTNAME` — host del workspace, ej. `adb-xxxx.azuredatabricks.net`
- `DATABRICKS_TOKEN` — personal access token (`dapi...`)
- `DATABRICKS_HTTP_PATH` — ej. `/sql/1.0/warehouses/<warehouse_id>` (el warehouse_id se extrae del final del path)
- `DATABRICKS_CATALOG` — (opcional) catalogo por defecto

## Como ejecutar una consulta

```bash
bash .claude/skills/databricks-query/scripts/run_query.sh "SELECT 1"
```

o desde un archivo `.sql` (recomendado para queries largas con multiples lineas/comentarios):

```bash
bash .claude/skills/databricks-query/scripts/run_query.sh --file ruta/a/consulta.sql
```

El script:
1. Envia la consulta a `POST /api/2.0/sql/statements` con `disposition=INLINE` y `wait_timeout=50s`.
2. Si no termina en ese lapso, hace polling a `GET /api/2.0/sql/statements/{statement_id}` cada 2s (hasta ~2 min).
3. Guarda la respuesta JSON completa en `.databricks_query_results/result_<timestamp>.json`.
4. Si el resultado viene dividido en multiples chunks (`manifest.total_chunk_count > 1`, pasa con
   resultados grandes, decenas de miles de filas en adelante), descarga cada chunk adicional y lo
   guarda como `result_<timestamp>_chunk1.json`, `_chunk2.json`, etc. — el archivo principal solo
   trae el chunk 0. Hay que sumar las filas de todos los archivos para tener el resultado completo.
5. Imprime en stdout la ruta del archivo principal (todo lo demas va a stderr).

## Guardrails de volumetria (obligatorios)

El script bloquea automaticamente (`exit 1`, sin llamar a la API) si detecta:

1. **Palabras de escritura/DDL** (`insert/update/delete/merge/create/alter/drop/truncate/grant/revoke`) — bloqueo permanente, no hay override. Este skill es solo lectura.
2. **Ni `LIMIT` ni `GROUP BY`** en la consulta — evita traer tablas completas sin querer. Override con `--force` solo si el volumen ya fue verificado.
3. **`dm_venta` (u otra tabla fact grande) sin filtro de fecha** (`fecha_venta`/`anomes`/`.mes`) — evita escanear todo el historico. Override con `--force`.

Ademas de lo que bloquea el script, aplicar siempre estas practicas antes de correr una consulta:

- **Analizar primero los campos/esquema** de las tablas involucradas (o revisar una consulta previa ya guardada) antes de escribir el SQL, para no adivinar nombres de columna.
- **Preferir agregacion sobre detalle.** Si la pregunta es "cuanto vendio X", usar `GROUP BY` + `SUM`, no traer cada fila transaccional.
- **Cuando SI se necesite detalle**, acotarlo con `LIMIT` (ej. 500-1000) y filtros especificos (cliente, gerencia, mes) — nunca detalle transaccional sin acotar.
- **Dimensionar antes de traer:** si no esta claro el volumen, correr primero un `SELECT COUNT(*)` con los mismos filtros (usando este mismo script) antes de pedir el detalle completo.
- **Nunca `SELECT *`** — columnas explicitas siempre, evita arrastrar campos innecesarios y hace el resultado legible.
- **Validar el resultado antes de reportarlo:** revisar `row_count`, nulos inesperados, y que las metricas cuadren (ej. `NR ≈ GSI + EXCISE + DSCTO`) antes de presentar cifras al usuario.
- **Guardar el `.sql` ejecutado** junto al resultado en `.databricks_query_results/` con nombre descriptivo (no solo el timestamp), para poder reusarlo/auditarlo despues.
- **Si el rango de fechas supera ~1 mes o no hay filtro por cliente/gerencia/direccion**, confirmar con el usuario antes de ejecutar (puede ser un scan costoso en el warehouse).

## Como leer el resultado

El JSON guardado trae:
- `manifest.schema.columns[]` — nombres/tipos de columna, en orden (solo en el archivo principal).
- `result.data_array[]` — filas, cada una como array de strings en el mismo orden que las columnas.
- `manifest.total_row_count` — total real de filas del resultado completo (util para validar que no
  falto ningun chunk: debe igualar la suma de `data_array` del archivo principal + todos los `_chunkN`).

Si existen archivos `_chunk1.json`, `_chunk2.json`, etc. junto al resultado principal, cada uno trae
su propio `data_array` (mismas columnas, mismo orden) — hay que concatenarlos con el del archivo
principal antes de analizar, no ignorarlos.

Despues de ejecutar el script, lee el archivo JSON resultante (Read tool) y arma una tabla legible
para el usuario combinando `manifest.schema.columns[].name` con `result.data_array`. No asumas
un numero fijo de columnas: siempre depende de la consulta.

Si `result.row_count` es 0, informa que la consulta no devolvio filas (no lo trates como error).

## Notas

- No pases SQL con comillas dobles sin escapar como argumento directo; para queries con comentarios
  `--` o strings, preferir siempre `--file`.
- Si el estado final es `FAILED`, el JSON guardado incluye `status.error.message` con el detalle
  (ej. columna inexistente, tabla no encontrada, permisos).
- El token nunca debe imprimirse ni loguearse; el script solo lo usa en el header `Authorization`.
