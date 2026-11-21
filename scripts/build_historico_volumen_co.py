"""Genera historico_volumen_co.html (historico mensual de volumen HL desde 2020, por gerencia y por CD)
a partir del resultado de querys/Query_CentroOriente_Historico_Gerencia_CD_Mensual.sql.

Uso: python scripts/build_historico_volumen_co.py <result.json> [--out historico_volumen_co.html]
Mismo look & feel que el artifact "Dashboard Volumen - CO". Orden de gerencias y CD desde run_config.json.
"""
import argparse, collections, glob, json, os

ap = argparse.ArgumentParser()
ap.add_argument("result")
ap.add_argument("--out", default="historico_volumen_co.html")
ap.add_argument("--partial", default="true", help="true si el ultimo mes de datos esta en curso")
ap.add_argument("--gerencia", help="acota a UNA gerencia (code exacto, ej. 'PE Ger P4 Pucall Hco')")
ap.add_argument("--cds", help="acota a estos CD (separados por coma); sin 'Otros CD'")
args = ap.parse_args()

cfg = json.load(open("run_config.json", encoding="utf-8"))
GER = [{"code": g["code"], "label": g["label"]} for g in cfg["gerencias"]]
CD_ORDER = cfg["cd_order"]

d = json.load(open(args.result, encoding="utf-8"))
rows = d["result"]["data_array"]
for c in sorted(glob.glob(args.result.replace(".json", "_chunk*.json"))):
    rows += json.load(open(c, encoding="utf-8"))["data_array"]
assert len(rows) == d["manifest"]["total_row_count"], "faltan filas (chunks)"

if args.gerencia:
    GER = [g for g in GER if g["code"] == args.gerencia]
    assert GER, "gerencia no encontrada en run_config.json"
    rows = [r for r in rows if r[0] == args.gerencia]
if args.cds:
    CD_ORDER = [c.strip() for c in args.cds.split(",")]
    rows = [r for r in rows if r[1] in CD_ORDER]
months = sorted({(int(r[3]), int(r[4])) for r in rows})
midx = {ym: i for i, ym in enumerate(months)}
N = len(months)
CATS = ["Beer", "Rtds", "Nabs"]

def blank():
    return {c: [0.0] * N for c in CATS}

cd_names = CD_ORDER if args.cds else CD_ORDER + ["Otros CD"]
data = {g["code"]: {n: blank() for n in cd_names} for g in GER}   # gerencia -> CD -> cat -> serie
for ger, cd, cat, y, m, hl in rows:
    if ger not in data:
        raise SystemExit(f"gerencia fuera de las 5 del run: {ger}")
    data[ger][cd if cd in cd_names else "Otros CD"][cat][midx[(int(y), int(m))]] += float(hl)

# cuadre: total por categoria/mes desde las filas crudas == suma de la estructura gerencia x CD
raw_tot = blank()
for ger, cd, cat, y, m, hl in rows:
    raw_tot[cat][midx[(int(y), int(m))]] += float(hl)
for cat in CATS:
    for i in range(N):
        st = sum(data[g][n][cat][i] for g in data for n in cd_names)
        assert abs(st - raw_tot[cat][i]) < 0.01, (cat, months[i], st, raw_tot[cat][i])

def r1(a):
    return [round(x, 1) for x in a]

payload = {
    "months": [list(ym) for ym in months],
    "ger": [{"code": g["code"], "label": g["label"]} for g in GER],
    "cd": cd_names,
    # d[gerencia][cd][cat] = serie mensual (solo combinaciones con volumen)
    "d": {g: {n: {c: r1(v[c]) for c in CATS if any(v[c])} for n, v in cds.items() if any(any(v[c]) for c in CATS)} for g, cds in data.items()},
}

scoped = bool(args.gerencia and args.cds)
glabel = GER[0]["label"] if args.gerencia else ""
texts = {
    "{{EYEBROW}}": (f"Gerencia {glabel} · {', '.join(CD_ORDER)} · Volumen (HL) · Histórico" if scoped else "Dirección Centro Oriente · Volumen (HL) · Histórico"),
    "{{PICK_TEXT}}": ("Elige un <b>CD</b> para acotar ambos cuadros." if scoped else "Elige una <b>gerencia</b> y, si quieres, un <b>CD</b> (el filtro de CD se acota a los CD de la gerencia elegida) para acotar ambos cuadros."),
    "{{CD_NOTE}}": ("Alcance acotado a los CD " + ", ".join(CD_ORDER) + " de la gerencia " + glabel + "; el resto de CD de la gerencia (volumen marginal) no se considera." if scoped else "Con <b>Total Dirección</b> y <b>Todos los CD</b>, cada CD aparece una vez con el volumen de todas las gerencias que abastece; al elegir una gerencia se muestra solo lo que ese CD vende a esa gerencia. <b>Otros CD</b> agrupa centros de otras zonas con clientes registrados en esta Dirección (volumen marginal)."),
    "{{SCOPE_NOTE}}": ("Alcance: gerencia " + glabel + " y CD " + ", ".join(CD_ORDER) + "." if scoped else "Solo clientes hoy asignados a Centro Oriente."),
}
html = open(os.path.join(os.path.dirname(__file__), "historico_volumen_co_template.html"), encoding="utf-8").read()
html = html.replace("{{DATA}}", json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
html = html.replace("{{PARTIAL}}", args.partial)
for k, v in texts.items():
    html = html.replace(k, v)
if scoped:
    html = html.replace("<title>Histórico Volumen - CO</title>", f"<title>Histórico Volumen - {glabel}</title>")
open(args.out, "w", encoding="utf-8").write(html)
print(f"OK: {args.out} -- {N} meses ({months[0]} a {months[-1]}), {len(GER)} gerencias, {len(cd_names)} CD; cuadre estructura==total OK")
