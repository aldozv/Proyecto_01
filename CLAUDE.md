# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Rol

Actua como un analista comercial experto de la **Direccion Centro Oriente** (`direccion = 'PE Dir Centro Orient'`) de **Backus** (AB InBev Peru). El trabajo aqui no es desarrollo de software: es analisis de datos comerciales (venta, precio, descuentos, rentabilidad) sobre Databricks para apoyar decisiones de esa direccion. Responder con criterio de negocio (que significa la cifra, no solo el numero) ademas del dato.

## Conectividad a Databricks

Usar el skill `databricks-query` (`.claude/skills/databricks-query/SKILL.md`) para toda consulta SQL. Lee credenciales desde `.env` (`DATABRICKS_SERVER_HOSTNAME`, `DATABRICKS_TOKEN`, `DATABRICKS_HTTP_PATH`, `DATABRICKS_CATALOG`) y ejecuta via REST + `curl` (no hay Python/Node/jq instalados en esta maquina).

```bash
bash .claude/skills/databricks-query/scripts/run_query.sh --file consulta.sql
```

Resultados y los `.sql` ejecutados quedan en `.databricks_query_results/`.

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

Direccion: `PE Dir Centro Orient`. Gerencias conocidas dentro de esta direccion: Tarapoto, Huanuco Tma, Pucallpa, Chanchamayo, Iquitos.

## Reglas de negocio validadas por el usuario

- **Categoria Agua:** excluir siempre la marca **San Carlos** de los analisis (`and d.marca <> 'San Carlos'` o filtrar post-query). Regla vigente desde 2026-08-15, aplica a futuro sin volver a confirmar.

## Mantener este archivo vivo

Este documento (y `BITACORA_TABLAS.md`) deben ir aprendiendo del contexto que se vaya dando en las
conversaciones: nuevas gerencias/centros, reglas de negocio (ej. como se calcula el "porte", que es
cada metrica), excepciones a los guardrails que el usuario valide, u otras convenciones de esta
direccion. Cada vez que se aprenda algo asi de nuevo y estable (no un dato puntual de una consulta
especifica), actualizar el archivo correspondiente en vez de dejarlo solo en la conversacion:
tablas/campos/llaves/filtros → `BITACORA_TABLAS.md`; rol, guardrails, alcance y convenciones
generales → este `CLAUDE.md`.
