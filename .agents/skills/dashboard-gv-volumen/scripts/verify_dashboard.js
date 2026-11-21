#!/usr/bin/env node
// Valida un dashboard generado por este skill ANTES de publicarlo como Artifact.
// Uso: node verify_dashboard.js <ruta_al_html>
//
// Corre el <script> del dashboard en una sandbox de Node (con un `document` stub) y, para
// CADA gerencia y CADA mes del rango, reconcilia:
//   1. Total (todos los CD, todas las categorias, todos los canales) == suma de las 3
//      categorias por separado.
//   2. Total == suma de los CD individuales (dentro del CD_LIST de esa gerencia).
//   3. Total == suma de los canales (post fold de "High End" en "DSD ON"), via sumCanalRow
//      (misma fuente que usa la seccion "Por Canal" para sus filas).
//   3b. El filtro global de Canal (sumBase/sumDim con un array de canales) coincide con
//      sumCanalRow canal por canal -- confirma que el canal agregado a IDX_BASE/IDX_MARCA/etc
//      no diverge de IDX_CANAL.
//   4. Total == suma de TODAS las marcas que aparecen para esa gerencia.
//   5. Total == suma de TODOS los formatos (pack) que aparecen para esa gerencia.
//   5b/5c. Idem para Pack (pack_xxx) y Marca x Formato.
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
// NOTA de arquitectura (desde que se agrego el filtro global de Canal, 2026-09-03): todos los
// indices de detalle (BASE, MARCA, FORMATO, PACK, MARCAFORMATO -- CANAL no cambio) llevan
// `canal` como dimension propia siempre en la posicion 3 de la key
// (gerencia|centro|categoria|canal|...detalle...). `sumBase`/`sumDim` reciben un ARRAY de
// canales (la seleccion del filtro global) y suman sobre todos ellos; `sumCanalRow` es la
// excepcion -- solo la usa la seccion "Por Canal", porque ahi el canal ES la fila (un valor
// puntual, no una seleccion a sumar), y sigue leyendo IDX_CANAL con su forma de siempre
// (gerencia|centro|categoria|canal, sin filtro adicional).
//
// Tambien corre varias combinaciones de Gerencia/Categoria/Canal/Centro/Periodo para confirmar
// que no tira excepciones, e imprime info de dims/periodos para que las revises -- el script
// prueba que el CALCULO es consistente, no que la cifra sea la respuesta correcta a la pregunta
// de negocio (eso lo revisas vos).
//
// Flag --quiet: suprime el bloque [info] puramente descriptivo (dims por gerencia, periodos,
// canales disponibles -- estable entre refreshes, no hace falta releerlo cada vez). El bloque
// "Total headline vs Total base" (detecta drift real del CD_LIST, ver SKILL.md) y todas las
// lineas OK/FAIL se imprimen siempre, con o sin --quiet.

const fs = require("fs");
const vm = require("vm");

const htmlPath = process.argv[2];
// --quiet: suprime los bloques "[info]" (dims por gerencia, canales disponibles, headline vs
// curado, etc.) -- solo imprime las lineas OK/FAIL de cada chequeo y el resumen final. Pensado
// para refreshes rutinarios donde ya conoces esos numeros y no queres gastar tokens releyendolos
// cada vez; en cualquier corrida que falle, segui viendo el detalle completo del FAIL igual
// (el flag no afecta la funcion `check`, solo los console.log informativos sueltos).
const quiet = process.argv.includes("--quiet");
if (!htmlPath) {
  console.error("Uso: node verify_dashboard.js <ruta_al_html> [--quiet]");
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
  const allCanales = CANAL_DIMS;
  for (const g of GERENCIA_LIST) {
    const gerCode = g.code;
    const allCd = CD_DIMS[gerCode];
    const allCat = CAT_ORDER;
    for (const p of PERIODS.month) {
      const [y, mo] = p.months[0];
      const total = sumBase([gerCode], allCd, allCat, allCanales, [[y,mo]]);

      let catSum = 0;
      for (const cat of allCat) catSum += sumBase([gerCode], allCd, [cat], allCanales, [[y,mo]]);
      if (Math.abs(total - catSum) > eps) bad.push({check:"total_vs_catsum", gerCode, y, mo, total, catSum});

      let cdSum = 0;
      for (const c of allCd) cdSum += sumBase([gerCode], [c], allCat, allCanales, [[y,mo]]);
      if (Math.abs(total - cdSum) > eps) bad.push({check:"total_vs_cdsum", gerCode, y, mo, total, cdSum});

      let canalSum = 0;
      for (const ch of allCanales) canalSum += sumCanalRow([gerCode], allCd, allCat, ch, [[y,mo]]);
      if (Math.abs(total - canalSum) > eps) bad.push({check:"total_vs_canalsum", gerCode, y, mo, total, canalSum});

      // filtro global de Canal (sumBase con un array de 1 canal) vs sumCanalRow (misma fuente
      // que "Por Canal") -- confirma que IDX_BASE (con canal agregado) no diverge de IDX_CANAL.
      for (const ch of allCanales) {
        const viaBase = sumBase([gerCode], allCd, allCat, [ch], [[y,mo]]);
        const viaCanalIdx = sumCanalRow([gerCode], allCd, allCat, ch, [[y,mo]]);
        if (Math.abs(viaBase - viaCanalIdx) > eps) bad.push({check:"canal_filtro_vs_seccion_canal", gerCode, y, mo, canal:ch, viaBase, viaCanalIdx});
      }

      const prefix = gerCode + "|";
      const marcaVals = new Set();
      for (const key of Object.keys(IDX_MARCA)) if (key.startsWith(prefix)) marcaVals.add(key.split("|")[4]);
      let marcaSum = 0;
      for (const mv of marcaVals) marcaSum += sumDim(IDX_MARCA, [gerCode], allCd, allCat, allCanales, mv, [[y,mo]]);
      if (Math.abs(total - marcaSum) > eps) bad.push({check:"total_vs_marcasum", gerCode, y, mo, total, marcaSum});

      const packVals = new Set();
      for (const key of Object.keys(IDX_FORMATO)) if (key.startsWith(prefix)) packVals.add(key.split("|")[4]);
      let packSum = 0;
      for (const pv of packVals) packSum += sumDim(IDX_FORMATO, [gerCode], allCd, allCat, allCanales, pv, [[y,mo]]);
      if (Math.abs(total - packSum) > eps) bad.push({check:"total_vs_packsum", gerCode, y, mo, total, packSum});

      // "Pack" (pack_xxx, agrupacion mas gruesa que Formato) -- IDX_PACK, no confundir con
      // IDX_FORMATO/total_vs_packsum de arriba (ese es el campo "pack" plano, seccion Formato).
      const packXxxVals = new Set();
      for (const key of Object.keys(IDX_PACK)) if (key.startsWith(prefix)) packXxxVals.add(key.split("|")[4]);
      let packXxxSum = 0;
      for (const pv of packXxxVals) packXxxSum += sumDim(IDX_PACK, [gerCode], allCd, allCat, allCanales, pv, [[y,mo]]);
      if (Math.abs(total - packXxxSum) > eps) bad.push({check:"total_vs_packxxxsum", gerCode, y, mo, total, packXxxSum});

      // "Marca x Formato" (IDX_MARCAFORMATO) -- dimVal compuesto "marca|formato" (2 dims en 1),
      // mismo patron que computeSortedComboDims: todo lo que sigue a gerencia|centro|categoria|canal.
      const mfVals = new Set();
      for (const key of Object.keys(IDX_MARCAFORMATO)) if (key.startsWith(prefix)) mfVals.add(key.split("|").slice(4).join("|"));
      let mfSum = 0;
      for (const mf of mfVals) mfSum += sumDim(IDX_MARCAFORMATO, [gerCode], allCd, allCat, allCanales, mf, [[y,mo]]);
      if (Math.abs(total - mfSum) > eps) bad.push({check:"total_vs_marcaformatosum", gerCode, y, mo, total, mfSum});
    }
  }

  // 6. multi-gerencia: TODAS las gerencias + union de CD, en cada mes, vs suma separada por gerencia
  const allCodes = GERENCIA_LIST.map(g=>g.code);
  const unionCd = unionCdDims(allCodes);
  for (const p of PERIODS.month) {
    const multi = sumBase(allCodes, unionCd, CAT_ORDER, allCanales, p.months);
    let sep = 0;
    for (const g of GERENCIA_LIST) sep += sumBase([g.code], CD_DIMS[g.code], CAT_ORDER, allCanales, p.months);
    if (Math.abs(multi - sep) > eps) bad.push({check:"multi_gerencia_union_vs_separado", period:p.key, multi, sep});
  }

  this.__BAD__ = bad;
})();
`;
vm.runInContext(reconcileCode, sandbox);
const bad = sandbox.__BAD__ || [];

for (const c of ["total_vs_catsum", "total_vs_cdsum", "total_vs_canalsum", "canal_filtro_vs_seccion_canal", "total_vs_marcasum", "total_vs_packsum", "total_vs_packxxxsum", "total_vs_marcaformatosum"]) {
  const failsForC = bad.filter(b => b.check === c);
  check(`${c} reconcilia en todas las gerencias y meses`, failsForC.length === 0, failsForC.slice(0, 5));
}
const multiFails = bad.filter(b => b.check === "multi_gerencia_union_vs_separado");
check("multi-gerencia (union de CD) == suma separada por gerencia, en todos los meses", multiFails.length === 0, multiFails.slice(0, 5));

// Este bloque NO se suprime con --quiet, a proposito: a diferencia del bloque de mas abajo
// (dims/periodos/canales, puramente descriptivo y estable), este chequea drift real -- el
// patron "canal DAs" (ver reglas_negocio.md) puede volver real de un mes a otro un CD que hoy es
// ruido marginal para una gerencia, y eso solo se ve comparando headline vs curado. Revisalo
// SIEMPRE, incluso en un refresh rutinario -- ver SKILL.md.
vm.runInContext(
  `
  console.log("\\n[info] Total headline (sin restriccion CD) vs Total base (CD curado), ultimo mes -- diferencias esperadas si el CD_LIST no captura el 100%:");
  const p = PERIODS.month[PERIODS.month.length-1];
  const [y,mo] = p.months[0];
  for (const g of GERENCIA_LIST) {
    const headline = sumMonths(IDX_GERENCIA[g.code], [[y,mo]]);
    const curado = sumBase([g.code], CD_DIMS[g.code], CAT_ORDER, CANAL_DIMS, [[y,mo]]);
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
      state.canales = new Set(["DSD OFF"]); renderAll();
      state.canales = new Set(CANAL_DIMS); renderAll();
      state.period = "quarter"; renderAll();
      state.period = "year"; renderAll();
      state.period = "ytd"; renderAll();
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
    // toggle de Canal con todas las gerencias (vista default)
    state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
    onGerenciaSetChange();
    for (const ch of CANAL_DIMS) {
      state.canales = new Set([ch]);
      renderAll();
    }
    state.canales = new Set(CANAL_DIMS);
    renderAll();
    // CD -> Gerencia (sentido inverso): elegir un solo CD de cada gerencia, ida y vuelta
    state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
    onGerenciaSetChange();
    for (const g of GERENCIA_LIST) {
      state.centros = new Set([CD_DIMS[g.code][0]]);
      onCentroSetChange();
      renderAll();
    }
    state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
    onGerenciaSetChange();
  `,
    sandbox
  );
  check("onGerenciaSetChange()/renderAll() no tiran excepcion para ninguna combinacion probada", true);
} catch (e) {
  check("onGerenciaSetChange()/renderAll() no tiran excepcion para ninguna combinacion probada", false, e.message);
}

// CD -> Gerencia: elegir un CD EXCLUSIVO de una sola gerencia (no compartido en ningun otro
// cd_list) debe dejar esa gerencia como la UNICA seleccionada -- si esto falla, revisa
// onCentroSetChange() en el template.
vm.runInContext(
  `
  this.__CD_OWNER_CHECK__ = [];
  for (const g of GERENCIA_LIST) {
    for (const c of CD_DIMS[g.code]) {
      const owners = GERENCIA_LIST.filter(g2 => CD_DIMS[g2.code].includes(c)).map(g2=>g2.code);
      if (owners.length === 1) { this.__CD_OWNER_CHECK__.push([g.code, c]); break; }
    }
  }
`,
  sandbox
);
const cdOwnerCases = sandbox.__CD_OWNER_CHECK__ || [];
let cdOwnerFails = [];
for (const [expectedGer, exclusiveCd] of cdOwnerCases) {
  vm.runInContext(
    `
    state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code));
    onGerenciaSetChange();
    state.centros = new Set(["${exclusiveCd}"]);
    onCentroSetChange();
    this.__RESULT_GERENCIAS__ = [...state.gerencias];
  `,
    sandbox
  );
  const resultGerencias = sandbox.__RESULT_GERENCIAS__ || [];
  if (resultGerencias.length !== 1 || resultGerencias[0] !== expectedGer) {
    cdOwnerFails.push({ exclusiveCd, expectedGer, gotGerencias: resultGerencias });
  }
}
vm.runInContext(`state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code)); onGerenciaSetChange();`, sandbox);
check("CD exclusivo -> auto-selecciona solo su gerencia (onCentroSetChange)", cdOwnerFails.length === 0, cdOwnerFails);

// CD -> Gerencia, caso de CD COMPARTIDO real (ver reglas_negocio.md): si el CD elegido ya
// pertenece al cd_list PROPIO de la gerencia ACTUALMENTE seleccionada, onCentroSetChange NO debe
// saltar a otra gerencia -- aunque ese mismo CD tambien sea el "dominante" de otra (ej. "CD
// Pucallpa" es volumen real tanto de Iquitos como de Pucall Hco; si el usuario esta viendo
// Iquitos y hace click en "CD Pucallpa", debe seguir viendo Iquitos, no saltar). Complementa el
// chequeo de arriba, que solo prueba el salto DESDE "Total Direccion".
vm.runInContext(
  `
  this.__SHARED_CD_CHECK__ = [];
  for (const g of GERENCIA_LIST) {
    for (const c of CD_DIMS[g.code]) {
      if (CD_DOMINANT_GERENCIA[c] && CD_DOMINANT_GERENCIA[c] !== g.code) {
        this.__SHARED_CD_CHECK__.push([g.code, c]);
        break;
      }
    }
  }
`,
  sandbox
);
const sharedCdCases = sandbox.__SHARED_CD_CHECK__ || [];
let sharedCdFails = [];
for (const [gerCode, sharedCd] of sharedCdCases) {
  vm.runInContext(
    `
    state.gerencias = new Set(["${gerCode}"]);
    onGerenciaSetChange();
    state.centros = new Set(["${sharedCd}"]);
    onCentroSetChange();
    this.__RESULT_GERENCIAS2__ = [...state.gerencias];
  `,
    sandbox
  );
  const resultGerencias = sandbox.__RESULT_GERENCIAS2__ || [];
  if (resultGerencias.length !== 1 || resultGerencias[0] !== gerCode) {
    sharedCdFails.push({ gerCode, sharedCd, gotGerencias: resultGerencias });
  }
}
vm.runInContext(`state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code)); onGerenciaSetChange();`, sandbox);
check(
  "CD compartido dentro de la gerencia actual -> NO cambia de gerencia (onCentroSetChange)",
  sharedCdFails.length === 0 && sharedCdCases.length > 0,
  { sharedCdFails, casesFound: sharedCdCases.length }
);

vm.runInContext(`state.gerencias = new Set(GERENCIA_LIST.map(g=>g.code)); onGerenciaSetChange();`, sandbox);
if (!quiet) {
  vm.runInContext(
    `
    console.log("\\n[info] marca dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedDims(IDX_MARCA,[g.code]).length));
    console.log("[info] formato dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedDims(IDX_FORMATO,[g.code]).length));
    console.log("[info] pack dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedDims(IDX_PACK,[g.code]).length));
    console.log("[info] marca x formato dims por gerencia:", GERENCIA_LIST.map(g=>g.label+":"+computeSortedComboDims(IDX_MARCAFORMATO,[g.code]).length));
    console.log("[info] periodos:", PERIODS.month.length, "mensuales,", PERIODS.quarter.length, "trimestrales,", PERIODS.year.map(p=>p.label).join(", "), "-- YTD:", PERIODS.ytd.map(p=>p.label).join(", "));
    console.log("[info] ultimo trimestre completo:", lastCompleteQuarter().label);
    console.log("[info] gerencias:", GERENCIA_LIST.map(g=>g.label).join(", "));
    console.log("[info] canales:", CANAL_DIMS.join(", "));
    console.log("[info] canales disponibles por gerencia (acotado, no siempre los 6):", GERENCIA_LIST.map(g=>g.label+":["+computeAvailableCanales([g.code]).join(",")+"]").join(" | "));
  `,
    sandbox
  );
}

console.log(`\n${failures === 0 ? "TODO OK" : failures + " CHEQUEO(S) FALLARON"} -- ${bad.length} discrepancia(s) totales.`);
process.exit(failures === 0 ? 0 : 1);
