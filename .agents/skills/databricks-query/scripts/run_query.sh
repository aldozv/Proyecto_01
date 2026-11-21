#!/usr/bin/env bash
# Ejecuta SQL en un Databricks SQL Warehouse via la Statement Execution API (REST + curl).
# No requiere Python/Node/jq — solo curl, disponible en Git Bash.
#
# Uso:
#   run_query.sh "SELECT 1"
#   run_query.sh --file consulta.sql
#   run_query.sh --force --file consulta.sql   # salta los guardrails de volumetria (no el bloqueo de escritura)
#
# Variables de entorno requeridas (se cargan automaticamente desde .env en la raiz del proyecto):
#   DATABRICKS_SERVER_HOSTNAME   ej. adb-xxxx.azuredatabricks.net
#   DATABRICKS_TOKEN             token personal (dapi...)
#   DATABRICKS_HTTP_PATH         ej. /sql/1.0/warehouses/<warehouse_id>
#   DATABRICKS_CATALOG           (opcional) catalogo por defecto
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ENV_FILE="${DATABRICKS_ENV_FILE:-$PROJECT_ROOT/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${DATABRICKS_SERVER_HOSTNAME:?falta DATABRICKS_SERVER_HOSTNAME en .env}"
: "${DATABRICKS_TOKEN:?falta DATABRICKS_TOKEN en .env}"
: "${DATABRICKS_HTTP_PATH:?falta DATABRICKS_HTTP_PATH en .env}"

WAREHOUSE_ID="${DATABRICKS_HTTP_PATH##*/}"
HOST="https://${DATABRICKS_SERVER_HOSTNAME}"

FORCE=0
SQL_FILE=""
INLINE_SQL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --file) SQL_FILE="${2:?uso: run_query.sh --file archivo.sql}"; shift 2 ;;
    *) INLINE_SQL="$1"; shift ;;
  esac
done

if [ -n "$SQL_FILE" ]; then
  SQL="$(cat "$SQL_FILE")"
else
  SQL="${INLINE_SQL:?uso: run_query.sh \"SQL\" | run_query.sh --file archivo.sql}"
fi

# --- Guardrails de volumetria/seguridad ---------------------------------
# 1) Nunca escritura, ni con --force.
if printf '%s' "$SQL" | grep -qiE '\b(insert|update|delete|merge|create|alter|drop|truncate|grant|revoke)\b'; then
  echo "BLOQUEADO: la consulta contiene una palabra clave de escritura/DDL (insert/update/delete/merge/create/alter/drop/truncate/grant/revoke)." >&2
  echo "Este skill es solo de lectura. Si de verdad necesitas eso, ejecutalo manualmente fuera de este script." >&2
  exit 1
fi

# 2) Toda consulta de detalle debe traer LIMIT, o ser una agregacion (GROUP BY).
if ! printf '%s' "$SQL" | grep -qiE '\blimit[[:space:]]+[0-9]'; then
  if ! printf '%s' "$SQL" | grep -qiE '\bgroup[[:space:]]+by\b'; then
    if [ "$FORCE" -ne 1 ]; then
      echo "BLOQUEADO: la consulta no tiene LIMIT ni GROUP BY. Agrega un LIMIT explicito (ej. LIMIT 1000) o agrega la consulta (GROUP BY)." >&2
      echo "Si el resultado ya esta acotado a proposito (ej. 1 cliente + 1 mes) y confirmaste el volumen, vuelve a correr con --force." >&2
      exit 1
    fi
    echo "AVISO: sin LIMIT ni GROUP BY, continuando por --force." >&2
  fi
fi

# 3) Tablas fact grandes conocidas requieren filtro de fecha explicito.
BIG_TABLES='dm_venta'
if printf '%s' "$SQL" | grep -qiE "\\b($BIG_TABLES)\\b"; then
  if ! printf '%s' "$SQL" | grep -qiE '\b(fecha_venta|anomes|\.mes\b)\b'; then
    if [ "$FORCE" -ne 1 ]; then
      echo "BLOQUEADO: la consulta toca una tabla fact grande (dm_venta) sin filtro visible por fecha_venta/anomes/mes." >&2
      echo "Sin filtro de fecha el warehouse puede escanear todo el historico. Agrega el filtro o vuelve a correr con --force si es intencional." >&2
      exit 1
    fi
    echo "AVISO: consulta sobre tabla fact grande sin filtro de fecha detectado, continuando por --force." >&2
  fi
fi
# -------------------------------------------------------------------------

# Escapa el SQL para incrustarlo como string JSON valido (barras, comillas, tabs, saltos de linea).
ESCAPED_SQL="$(printf '%s' "$SQL" \
  | sed 's/\\/\\\\/g' \
  | sed 's/"/\\"/g' \
  | sed $'s/\t/\\\\t/g' \
  | sed ':a;N;$!ba;s/\n/\\n/g')"

CATALOG_JSON=""
if [ -n "${DATABRICKS_CATALOG:-}" ]; then
  CATALOG_JSON=",\"catalog\":\"${DATABRICKS_CATALOG}\""
fi

PAYLOAD_FILE="$(mktemp)"
trap 'rm -f "$PAYLOAD_FILE"' EXIT
printf '{"warehouse_id":"%s","statement":"%s","wait_timeout":"50s","disposition":"INLINE"%s}' \
  "$WAREHOUSE_ID" "$ESCAPED_SQL" "$CATALOG_JSON" > "$PAYLOAD_FILE"

OUT_DIR="${DATABRICKS_OUT_DIR:-$PROJECT_ROOT/.databricks_query_results}"
mkdir -p "$OUT_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
RESULT_FILE="$OUT_DIR/result_${TS}.json"

echo "Enviando consulta al warehouse ${WAREHOUSE_ID}..." >&2
RESPONSE="$(curl -sS -X POST "$HOST/api/2.0/sql/statements" \
  -H "Authorization: Bearer $DATABRICKS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @"$PAYLOAD_FILE")"

STATEMENT_ID="$(printf '%s' "$RESPONSE" | grep -oE '"statement_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')"
STATE="$(printf '%s' "$RESPONSE" | grep -oE '"status"[[:space:]]*:[[:space:]]*\{[[:space:]]*"state"[[:space:]]*:[[:space:]]*"[A-Z_]+"' | grep -oE '"[A-Z_]+"$' | tr -d '"')"

if [ -z "$STATEMENT_ID" ]; then
  echo "Error: no se pudo obtener statement_id. Respuesta cruda:" >&2
  printf '%s\n' "$RESPONSE" > "$RESULT_FILE"
  cat "$RESULT_FILE" >&2
  exit 1
fi

echo "statement_id=$STATEMENT_ID estado_inicial=$STATE" >&2

ATTEMPTS=0
while [ "$STATE" = "PENDING" ] || [ "$STATE" = "RUNNING" ]; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -gt 60 ]; then
    echo "Timeout esperando resultado (statement_id=$STATEMENT_ID)" >&2
    exit 1
  fi
  sleep 2
  RESPONSE="$(curl -sS -X GET "$HOST/api/2.0/sql/statements/$STATEMENT_ID" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN")"
  STATE="$(printf '%s' "$RESPONSE" | grep -oE '"status"[[:space:]]*:[[:space:]]*\{[[:space:]]*"state"[[:space:]]*:[[:space:]]*"[A-Z_]+"' | grep -oE '"[A-Z_]+"$' | tr -d '"')"
  echo "estado: $STATE" >&2
done

printf '%s' "$RESPONSE" > "$RESULT_FILE"

if [ "$STATE" != "SUCCEEDED" ]; then
  echo "La consulta termino en estado $STATE. Ver detalle en $RESULT_FILE" >&2
  exit 1
fi

# Si el resultado viene dividido en varios chunks, Databricks solo devuelve el
# primero inline; hay que pedir los siguientes por separado (uno por archivo,
# sin depender de jq/python para mergear JSON).
TOTAL_CHUNKS="$(printf '%s' "$RESPONSE" | grep -oE '"total_chunk_count"[[:space:]]*:[[:space:]]*[0-9]+' | grep -oE '[0-9]+$')"
if [ -n "$TOTAL_CHUNKS" ] && [ "$TOTAL_CHUNKS" -gt 1 ]; then
  echo "Resultado dividido en $TOTAL_CHUNKS chunks, descargando los restantes..." >&2
  BASE_NAME="${RESULT_FILE%.json}"
  CHUNK_IDX=1
  while [ "$CHUNK_IDX" -lt "$TOTAL_CHUNKS" ]; do
    CHUNK_FILE="${BASE_NAME}_chunk${CHUNK_IDX}.json"
    curl -sS -X GET "$HOST/api/2.0/sql/statements/$STATEMENT_ID/result/chunks/$CHUNK_IDX" \
      -H "Authorization: Bearer $DATABRICKS_TOKEN" > "$CHUNK_FILE"
    echo "Chunk $CHUNK_IDX guardado en: $CHUNK_FILE" >&2
    CHUNK_IDX=$((CHUNK_IDX + 1))
  done
fi

echo "OK. Resultado guardado en: $RESULT_FILE" >&2
echo "$RESULT_FILE"
