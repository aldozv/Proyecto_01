"""Genera resumen_ytd_co.html (resumen YTD de la regional Centro Oriente por KPI, canal y gerencia, 2021-2026).

Uso: python scripts/build_resumen_ytd_co.py <result_gerencia_canal.json> [--out resumen_ytd_co.html] [--ytd-month 10]
Entrada: resultado de querys/Query_CentroOriente_Historico_Gerencia_Canal_Mensual.sql
(gerencia x canal x categoria x anio x mes). 'High End' se pliega en 'DSD ON'.
"""
import argparse, glob, json

ap = argparse.ArgumentParser()
ap.add_argument("result")
ap.add_argument("--out", default="resumen_ytd_co.html")
ap.add_argument("--template", default="scripts/resumen_ytd_co_template.html")
ap.add_argument("--ytd-month", type=int, default=10, help="ultimo mes CERRADO del YTD")
args = ap.parse_args()

cfg = json.load(open("run_config.json", encoding="utf-8"))
GER = [{"code": g["code"], "label": g["label"]} for g in cfg["gerencias"]]
CAN = ["DSD OFF", "DSD ON", "Mayoristas", "Eventos", "DAs", "Key Accounts"]
CATS = ["Beer", "Rtds", "Nabs"]

d = json.load(open(args.result, encoding="utf-8"))
rows = d["result"]["data_array"]
for c in sorted(glob.glob(args.result.replace(".json", "_chunk*.json"))):
    rows += json.load(open(c, encoding="utf-8"))["data_array"]
assert len(rows) == d["manifest"]["total_row_count"], "faltan filas (chunks)"

months = sorted({(int(r[3]), int(r[4])) for r in rows})
midx = {ym: i for i, ym in enumerate(months)}
N = len(months)
codes = {g["code"] for g in GER}
unclassified = 0.0
data = {g["code"]: {c: {k: [0.0] * N for k in CATS} for c in CAN} for g in GER}
for ger, canal, cat, y, m, hl in rows:
    if ger not in codes:
        raise SystemExit(f"gerencia fuera del run: {ger}")
    canal = "DSD ON" if canal == "High End" else canal
    if canal == "Sin clasificar":
        unclassified += float(hl)
        continue
    if canal not in CAN:
        raise SystemExit(f"canal no esperado: {canal}")
    data[ger][canal][cat][midx[(int(y), int(m))]] += float(hl)

assert abs(unclassified) < 1, f"hay volumen 'Sin clasificar': {unclassified}"
payload = {
    "months": [list(ym) for ym in months],
    "ger": GER,
    "canal": CAN,
    "d": {g: {c: {k: [round(x, 1) for x in v] for k, v in cats.items() if any(v)} for c, cats in cs.items()} for g, cs in data.items()},
}
html = open(args.template, encoding="utf-8").read()
html = html.replace("{{DATA}}", json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
html = html.replace("{{YTD_M}}", str(args.ytd_month))
open(args.out, "w", encoding="utf-8").write(html)
print(f"OK: {args.out} -- {N} meses ({months[0]} a {months[-1]}), YTD a mes {args.ytd_month}, {len(GER)} gerencias, {len(CAN)} canales")
