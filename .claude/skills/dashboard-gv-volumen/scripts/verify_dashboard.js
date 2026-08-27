#!/usr/bin/env node
// Valida un dashboard generado por este skill ANTES de publicarlo como Artifact.
// Uso: node verify_dashboard.js <ruta_al_html>
//
// Corre el <script> del dashboard en una sandbox de Node (con un `document` stub) y, para
// CADA gerencia y CADA mes del rango, reconcilia:
//   1. Total (todos los CD, todas las categorias) == suma de las 3 categorias por separado.
//   2. Total == suma de los CD individuales (dentro del CD_LIST de esa gerencia).
//   3. Total == suma de los canales (post fold de "High End" en "DSD ON").
//   4. Total == suma de TODAS las marcas que aparecen para esa gerencia.
//   5. Total == suma de TODOS los formatos (pack) que aparecen para esa gerencia.
//   6. **Multi-gerencia**: el Total con TODAS las gerencias + la UNION de CD seleccionadas al
//      mismo tiempo debe ser EXACTAMENTE igual a la suma de cada gerencia calculada por
//      separado con su propio CD_LIST. Esta es la verificacion mas importante del set: si el
//      filtro de Centro del toolbar (que muestra la union de CD de todas las gerencias
//      seleccionadas) no esta bien acotado por gerencia dentro de sumBase/sumDim, un CD
//      deliberadamente excluido para una gerencia puede "colarse" de vuelta cuando otra
//      gerencia seleccionada SI tiene ese mismo nombre de CD en su propio CD_LIST (bug real
//      encontrado 2026-08-27 con el caso Tarapoto/CD San Benedicto+Ate vs DA Jun Puc -- ver
//      references/reglas_negocio.md). Si este chequeo falla, revisa que sumBase/sumDim filtren
//      `centros` contra `CD_DIMS[g]` (el CD_LIST de CADA gerencia), no contra la lista
//      compartida del toolbar.
//
// Tambien corre el toggle multi-select de Gerencia con varias combinaciones (todas, una sola,
// un subconjunto) y de Categoria/Centro/Periodo para confirmar que no tira excepciones, e
// imprime los KPI de highlights (para la seleccion default = todas las gerencias) para que los
// revises -- el script prueba que el CALCULO es consistente, no que la cifra sea la respuesta
// correcta a la pregunta de negocio (eso lo revisas vos).

const fs = require("fs");
const vm = require("vm");

const htmlPath = process.argv[2];
if (!htmlPath) {
  console.error("Uso: node verify_dashboard.js <ruta_al_html>");
  process.exit(1);
}

const html = fs.readFileSync(htmlPath, "utf8");
const m = html.match(/<script>([\s\S]*)<\/script>/);
if (!m) {
  console.error("No se encontro <script> en el HTML -- ¿es un archivo de este template?");
  process.exit(1);
}
const code = m[1];

const sandbox = {
  console,
  document: {
    getElementById: () => ({ innerHTML: "", textContent: "", addEventListener() {}, classList: { toggle() {} } }),
    querySelectorAll: () => ({ forEach() {} }),
  },
};
vm.createContext(sandbox);
try {
  vm.runInContext(code, sandbox);
} catch (e) {
  console.error("FALLO al ejecutar el <script> del dashboard:", e.message);
  process.exit(1);
}

let failures = 0;
function check(label, cond, detail) {
  if (cond) console.log("OK  ", label);
  else { console.log("FAIL", label, detail !== undefined ? JSON.stringify(detail) : ""); failures++; }
}

const EPS = 0.02;

const reconcileCode = `
(function(){
  const eps = ${EPS};
  const bad = [];
  for (const g of GERENCIA_LIST) {
    const gerCode = g.code;
    const allCd = CD_DIMS[gerCode];
    const allCat = CAT_ORDER;
    for (const p of PERIODS.month) {
      const [y, mo] = p.months[0];
      const total = sumBase([gerCode], allCd, allCat, [[y,mo]]);

      let catSum = 0;
      for (const cat of allCat) catSum += sumBase([gerCode], allCd, [cat], [[y,mo]]);
      if (Math.abs(total - catSum) > eps) bad.push({check:"total_vs_catsum", gerCode, y, mo, total, catSum});

      let cdSum = 0;
      for (const c of allCd) cdSum += sumBase([gerCode], [c], allCat, [[y,mo]]);
      if (Math.abs(total - cdSum) > eps) bad.push({check:"total_vs_cdsum", gerCode, y, mo, total, cdSum});

      let canalSum = 0;
      for (const ch of CANAL_DIMS) canalSum += sumDim(IDX_CANAL, [gerCode], allCd, allCat, ch, [[y,mo]]);
      if (Math.abs(total - canalSum) > eps) bad.push({check:"total_vs_canalsum", gerCode, y, mo, total, canalSum});

      const prefix = gerCode + "|";
      const marcaVals = new Set();
      for (const key of Object.keys(IDX_MARCA)) if (key.startsWith(prefix)) marcaVals.add(key.split("|")[3]);
      let marcaSum = 0;
      for (const mv of marcaVals) marcaSum += sumDim(IDX_MARCA, [gerCode], allCd, allCat, mv, [[y,mo]]);
      if (Math.abs(total - marcaSum) > eps) bad.push({check:"total_vs_marcasum", gerCode, y, mo, total, marcaSum});

      const packVals = new Set();
      for (const key of Object.keys(IDX_FORMATO)) if (key.startsWith(prefix)) packVals.add(key.split("|")[3]);
      let packSum = 0;
      for (const pv of packVals) packSum += sumDim(IDX_FORMATO, [gerCode], allCd, allCat, pv, [[y,mo]]);
      if (Math.abs(total - packSum) > eps) bad.push({check:"total_vs_packsum", gerCode, y, mo, total, packSum});
    }
  }

  // 6. multi-gerencia: TODAS las gerencias + union de CD, en cada mes, vs suma separada por gerencia
  const allCodes = GERENCIA_LIST.map(g=>g.code);
  const unionCd = unionCdDims(allCodes);
  for (const p of PERIODS.month) {
    const multi = sumBase(allCodes, unionCd, CAT_ORDER, p.months);
    let sep = 0;
    for (const g of GERENCIA_LIST) sep += sumBase([g.code], CD_DIMS[g.code], CAT_ORDER, p.months);
    if (Math.abs(multi - sep) > eps) bad.push({check:"multi_gerencia_union_vs_separado", period:p.key, multi, sep});
  }

  this.__BAD__ = bad;
})();
`;
vm.runInContext(reconcileCode, sandbox);
const bad = sandbox.__BAD__ || [];

for (const c of ["total_vs_catsum", "total_vs_cdsum", "total_vs_canalsum", "total_vs_marcasum", "total_vs_packsum"]) {
  const failsForC = bad.filter(b => b.check === c);
  check(`${c} reconcilia en todas las gerencias y meses`, failsForC.length === 0, failsForC.slice(0, 5));
}
const multiFails = bad.filter(b => b.check === "multi_gerencia_union_vs_separado");
check("multi-gerencia (union de CD) == suma separada por gerencia, en todos los meses", multiFails.length === 0, multiFails.slice(0, 5));

vm.runInContext(
  `
  console.log("\\n[info] Total headline (sin restriccion CD) vs Total base (CD curado), ultimo mes -- diferencias esperadas si el CD_LIST no captura el 100%:");
  const p = PERIODS.month[PERIODS.month.length-1];
  const [y,mo] = p.months[0];
  for (const g of GERENCIA_LIST) {
    const headline = sumMonths(IDX_GERENCIA[g.code], [[y,mo]]);
    const curado = sumBase([g.code], CD_DIMS[g.code], CAT_ORDER, [[y,mo]]);
    const pct = headline>0 ? (100*(headline-curado)/headline).toFixed(2) : "n/a";
    console.log(" -", g.label, p.label, "headline:", headline.toFixed(1), "curado:", curado.toFixed(1), "diff:", pct + "%");
  }
`,
  sandbox
);

try {
  vm.runInContext(
    `
    // default: todas seleccionadas (vista de Direccion)
    renderAll();
    // cada gerencia sola, ida y vuelta
    for (const g of GERENCIA_LIST) {
      state.gerencias = new Set([g.code]);
      onGerenciaSetChange();
      state.categories = new Set(["Beer"]); renderAll();
      state.categories = new Set(CAT_ORDER); renderAll();
      state.period = "quarter"; renderAll();
      state.period = "year"; renderAll();
      state.period = "month"; renderAll();
    }
    // volver a todas, y un subconjunto de 2
    state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
    onGerenciaSetChange();
    if (GERENCIA_LIST.length >= 2) {
      state.gerencias = new Set([GERENCIA_LIST[0].code, GERENCIA_LIST[1].code]);
      onGerenciaSetChange();
      renderAll();
    }
  `,
    sandbox
  );
  check("onGerenciaSetChange()/renderAll() no tiran excepcion para ninguna combinacion probada", true);
} catch (e) {
  check("onGerenciaSetChange()/renderAll() no tiran excepcion para ninguna combinacion probada", false, e.message);
}

vm.runInContext(
  `
  state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
  onGerenciaSetChange();
  console.log("\\n[info] marca dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedDims(IDX_MARCA,[g.code]).length));
  console.log("[info] formato dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedDims(IDX_FORMATO,[g.code]).length));
  console.log("[info] periodos:", PERIODS.month.length, "mensuales,", PERIODS.quarter.length, "trimestrales,", PERIODS.year.map(p=>p.label).join(", "));
  console.log("[info] ultimo trimestre completo:", lastCompleteQuarter().label);
  console.log("[info] gerencias:", GERENCIA_LIST.map(g=>g.label).join(", "));
`,
  sandbox
);

console.log(`\n${failures === 0 ? "TODO OK" : failures + " CHEQUEO(S) FALLARON"} -- ${bad.length} discrepancia(s) totales.`);
process.exit(failures === 0 ? 0 : 1);
