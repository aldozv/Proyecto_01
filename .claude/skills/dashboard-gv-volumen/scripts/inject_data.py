#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Rellena assets/dashboard_template.html con los datos de un run puntual (una o mas gerencias,
un rango de anios) y escribe el HTML final listo para publicar como Artifact.

Uso:
    python inject_data.py --config run_config.json --out salida.html

run_config.json (ver run_config.example.json en esta misma carpeta):
{
  "direccion_label": "Dirección Centro Oriente",
  "eyebrow_text": "Dirección Centro Oriente · Volumen (HL)",
  "page_title_tag": "Centro Oriente Volumen",
  "page_title_default": "Ventas por Gerencia — Centro Oriente",
  "year_min": 2025,
  "year_max": 2026,
  "latest_month": 8,
  "latest_month_is_partial": true,
  "footer_scope_note": "Incluye las 4 gerencias geográficas de Centro Oriente + DA Jun Puc (Distribuidor Autorizado). El filtro Gerencia del toolbar es multi-select: con todas marcadas ves el total de la Dirección.",
  "gerencias": [
    {"code": "PE Ger P4 Pucall Hco", "label": "Pucallpa",
     "cd_list": ["CD Pucallpa", "CD Huánuco", "CD Tingo María"],
     "cd_note": "CD Pucallpa, CD Huánuco, CD Tingo María."},
    ...
  ],
  "raw_files": {
    "RAW_GERENCIA": "resultados/gerencia_mensual.json",
    "RAW_BASE": "resultados/base_cd_categoria_mensual.json",
    "RAW_CANAL": "resultados/canal_cd_categoria_mensual.json",
    "RAW_MARCA": "resultados/marca_cd_categoria_mensual.json",
    "RAW_FORMATO": "resultados/formato_cd_categoria_mensual.json"
  }
}

Cada archivo en "raw_files" es el JSON tal cual lo guarda run_query.sh del skill
databricks-query (con result.data_array) -- este script no reordena ni transforma filas, solo
las serializa a un literal JS. Las reglas de negocio (agrupacion Beer/Rtds/Nabs, exclusion San
Mateo, fold de "High End" en "DSD ON", formula de HL) ya estan resueltas en el propio template
-- lo unico que este script arma a partir del config es GERENCIA_LIST/CD_DIMS/CD_NOTE/
DIRECCION_LABEL.

El template soporta multiples gerencias seleccionadas a la vez (toggle multi-select, todas
seleccionadas por defecto = vista de la Direccion completa) -- cada gerencia solo suma sus
PROPIOS CD confirmados en `cd_list`, aunque el filtro de Centro del toolbar muestre la union de
CD de todas las gerencias seleccionadas (ver references/reglas_negocio.md, seccion "Gerencia
multi-select y el bug de CD compartidos" antes de tocar la logica de agregacion).

Nota: `cd_list` de cada gerencia debe ser exactamente el subconjunto de CD que confirmaste con
el usuario (ver references/reglas_negocio.md) -- este script no valida que las queries hayan
sido corridas con el mismo `{{CD_IN_LIST}}` (union de todos los cd_list), eso lo hace
verify_dashboard.js reconciliando los totales.
"""
import argparse
import json
import os

RAW_KEYS = ["RAW_GERENCIA", "RAW_BASE", "RAW_CANAL", "RAW_MARCA", "RAW_FORMATO", "RAW_PACK", "RAW_MARCAFORMATO"]

TEXT_KEYS = [
    "eyebrow_text", "page_title_tag", "page_title_default", "footer_scope_note",
]


def load_data_array(json_path):
    with open(json_path, encoding="utf-8") as f:
        payload = json.load(f)
    rows = payload["result"]["data_array"]
    chunk_count = payload["manifest"].get("total_chunk_count", 1)
    if chunk_count > 1:
        base, ext = os.path.splitext(json_path)
        for i in range(1, chunk_count):
            chunk_path = f"{base}_chunk{i}{ext}"
            with open(chunk_path, encoding="utf-8") as f:
                chunk = json.load(f)
            # los archivos _chunkN.json que guarda run_query.sh son el objeto de chunk "pelado"
            # (chunk_index/row_offset/row_count/data_array), NO envueltos en {"result": {...}}
            # como el archivo principal -- distinto del payload de la statement completa.
            rows += chunk["data_array"]
    return rows


def to_js_array(rows):
    return "[" + ",".join(json.dumps(r, ensure_ascii=False) for r in rows) + "]"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    ap.add_argument("--template", default=None)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    with open(args.config, encoding="utf-8") as f:
        cfg = json.load(f)

    template_path = args.template or os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "dashboard_template.html"
    )
    with open(template_path, encoding="utf-8") as f:
        html = f.read()

    missing_raw = [k for k in RAW_KEYS if k not in cfg.get("raw_files", {})]
    if missing_raw:
        raise SystemExit(f"Faltan raw_files en el config: {missing_raw}")

    for key in RAW_KEYS:
        rows = load_data_array(cfg["raw_files"][key])
        placeholder = "{{" + key + "}}"
        if placeholder not in html:
            raise SystemExit(f"Placeholder {placeholder} no encontrado en el template")
        html = html.replace(placeholder, to_js_array(rows), 1)
        print(f"{key}: {len(rows)} filas inyectadas")

    gerencias = cfg["gerencias"]
    if not gerencias:
        raise SystemExit("run_config.json necesita al menos 1 gerencia en 'gerencias'")

    gerencia_list_js = json.dumps(
        [{"code": g["code"], "label": g["label"]} for g in gerencias], ensure_ascii=False
    )
    cd_dims_js = json.dumps({g["code"]: g["cd_list"] for g in gerencias}, ensure_ascii=False)
    cd_note_js = json.dumps({g["code"]: g["cd_note"] for g in gerencias}, ensure_ascii=False)
    # orden de exhibicion de CD en el toolbar y en "Por Centro de Distribucion" -- opcional; si
    # no se define en el config, cae al orden de aparicion (union de cd_list por gerencia, en el
    # orden de GERENCIA_LIST) que ya tenia el template antes de este placeholder.
    cd_order_js = json.dumps(cfg.get("cd_order", []), ensure_ascii=False)

    direccion_label_js = json.dumps(cfg["direccion_label"], ensure_ascii=False)

    for placeholder, val in (
        ("{{GERENCIA_LIST_JS}}", gerencia_list_js),
        ("{{CD_DIMS_JS}}", cd_dims_js),
        ("{{CD_NOTE_JS}}", cd_note_js),
        ("{{CD_ORDER_JS}}", cd_order_js),
        ("{{DIRECCION_LABEL}}", direccion_label_js),
    ):
        if placeholder not in html:
            raise SystemExit(f"Placeholder {placeholder} no encontrado en el template")
        html = html.replace(placeholder, val, 1)

    scalars = {
        "YEAR_MIN": str(cfg["year_min"]),
        "YEAR_MAX": str(cfg["year_max"]),
        "LATEST_MONTH": str(cfg["latest_month"]),
        "LATEST_MONTH_IS_PARTIAL": "true" if cfg["latest_month_is_partial"] else "false",
        "EYEBROW_TEXT": cfg["eyebrow_text"],
        "PAGE_TITLE_TAG": cfg["page_title_tag"],
        "PAGE_TITLE_DEFAULT": cfg["page_title_default"],
        "FOOTER_SCOPE_NOTE": cfg["footer_scope_note"],
    }
    for key, val in scalars.items():
        placeholder = "{{" + key + "}}"
        if placeholder not in html:
            raise SystemExit(f"Placeholder {placeholder} no encontrado en el template")
        html = html.replace(placeholder, val)

    remaining = [tok for tok in html.split("{{")[1:] if "}}" in tok]
    if remaining:
        leftover = ["{{" + tok.split("}}")[0] + "}}" for tok in remaining]
        raise SystemExit(f"Quedaron placeholders sin reemplazar: {leftover}")

    with open(args.out, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"\nOK: escrito {args.out}")


if __name__ == "__main__":
    main()
