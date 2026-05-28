module verilang::RunnerJson

// ─────────────────────────────────────────────────────────────────────────────
//  Puente Rascal -> Kotlin.
//  Kotlin (VeriLangService.kt) llama:
//     java -jar rascal-shell-stable.jar verilang::RunnerJson /ruta/archivo.vl
//  Este modulo parsea, (TODO: chequea tipos) y hace UN println de un objeto JSON
//  cuyas claves DEBEN coincidir con RunResult.kt y con CONTRATO_JSON.md.
//
//  REGLA: no imprimir NADA antes del JSON (ni logs). Solo el println final.
//
//  Estado: BASE LISTA. Parsea y reporta modulo + usings + conteos.
//  Lo sustantivo queda marcado con  TODO(A)  para la Persona A.
// ─────────────────────────────────────────────────────────────────────────────

import verilang::Syntax;
import verilang::AST;
import verilang::Parser;        // parseModule, implodeModule
import verilang::PrettyPrinter; // TODO(A): refactorizar para que RETORNE str
import verilang::TypePalCheck;  // tmodelFromTree, getMessages (via TypePal)

import ParseTree;
import Message;
import IO;
import Set;
import List;
import String;

// ─── Utilidades JSON (no tocar; las usa todo el modulo) ─────────────────────

str esc(str s) =
    replaceAll(replaceAll(replaceAll(replaceAll(
        s, "\\", "\\\\"), "\"", "\\\""), "\n", "\\n"), "\t", "\\t");

str jsonArr(list[str] items) =
    "[<intercalate(", ", [ "\"<esc(i)>\"" | i <- items ])>]";

// Objeto JSON final. El orden de los parametros sigue el de CONTRATO_JSON.md.
str jsonResult(
    bool success,
    str modName,
    bool parseOk,
    bool tcOk,
    bool semOk,
    list[str] tcErrs,
    list[str] semErrs,
    list[str] output,
    str err,
    str codigoFormateado,
    str resumen
) =
    "{\"success\":<success>,"
    + "\"module\":\"<esc(modName)>\","
    + "\"parseOk\":<parseOk>,"
    + "\"typeCheckOk\":<tcOk>,"
    + "\"semanticOk\":<semOk>,"
    + "\"typeErrors\":<jsonArr(tcErrs)>,"
    + "\"semanticErrors\":<jsonArr(semErrs)>,"
    + "\"output\":<jsonArr(output)>,"
    + "\"error\":\"<esc(err)>\","
    + "\"codigoFormateado\":\"<esc(codigoFormateado)>\","
    + "\"resumen\":\"<esc(resumen)>\"}";

// ─── Inventario rapido del modulo (conteos) ─────────────────────────────────
//  Base minima para que la UI muestre algo. La version "rica" (listar cada
//  declaracion con su firma) la produce el PrettyPrinter -> ver TODO(A).

str inventarioResumen(Module m) {
    list[Funcion] fs = m.funciones;
    int nSpaces = size([ f | f <- fs, defSpace(_, _)    := f ]);
    int nOps    = size([ f | f <- fs, defOp(_, _, _)    := f ]);
    int nRels   = size([ f | f <- fs, defRel(_, _, _)   := f ]);
    int nRules  = size([ f | f <- fs, defRule(_, _)     := f ]);
    int nExprs  = size([ f | f <- fs, defEx(_, _)       := f ]);
    int nVars   = ( 0 | it + size(ds) | defVar(list[VarDecl] ds) <- fs );
    return "Spaces: <nSpaces>  |  Operators: <nOps>  |  Relations: <nRels>  |  Variables: <nVars>  |  Rules: <nRules>  |  Expressions: <nExprs>";
}

// Lista que se muestra en la UI: el modulo y sus imports (using).
// El PDF pide "a list with the modules": en VeriLang hay 1 modulo por archivo,
// asi que listamos el modulo + sus usings.
list[str] listaModulos(Module m) {
    list[str] info = [ "Modulo: <m.name>" ];
    for (str u <- m.usings) info += "  using <u>";
    return info;
}

// ─── Punto de entrada ───────────────────────────────────────────────────────

void main(list[str] args) {

    // 1) Leer archivo fuente
    str src;
    loc file;
    try {
        file = isEmpty(args)
            ? |project://verilang-project/tests/set.vl|   // por defecto, para probar desde el shell de Rascal
            : (startsWith(args[0], "/") ? |file:///| + args[0] : |cwd:///| + args[0]);
        src = readFile(file);
    } catch e: {
        println(jsonResult(false, "", false, false, false, [], [], [], "No se pudo leer el archivo: <e>", "", ""));
        return;
    }

    // 2) Parsing  -> parseOk + error de Rascal si falla (lo pide el PDF: "fail" + error)
    start[DefMod] cst;
    try {
        cst = parse(#start[DefMod], src, file);
    } catch ParseError(loc at): {
        println(jsonResult(false, "", false, false, false, [], [], [], "Parse FAIL: error de sintaxis en <at>", "", ""));
        return;
    } catch e: {
        println(jsonResult(false, "", false, false, false, [], [], [], "Parse FAIL: <e>", "", ""));
        return;
    }

    // 3) Construir AST
    Module m;
    try {
        m = implodeModule(cst.top);
    } catch e: {
        println(jsonResult(false, "", true, false, false, [], [], [], "Error construyendo AST: <e>", "", ""));
        return;
    }

    str modName    = m.name;
    list[str] info = listaModulos(m);
    str resumen    = inventarioResumen(m);

    // 4) Chequeo de tipos (TypePal)
    // ── TODO(A): enganchar el verificador real. Sugerencia con lo que ya existe
    //    en TypePalCheck.rsc (tmodelFromTree / getMessages):
    //
    //    bool   tcOk   = true;
    //    list[str] tcErrs = [];
    //    try {
    //        TModel tm = tmodelFromTree(cst);
    //        list[Message] msgs = getMessages(tm);
    //        tcErrs = [ "<msg>" | Message msg <- msgs, msg is error ];
    //        tcOk   = isEmpty(tcErrs);
    //    } catch e: { tcOk = false; tcErrs = ["Error en type check: <e>"]; }
    //
    //    Mientras tanto, la BASE deja el parser funcionando y tipos en "ok":
    bool tcOk = true;
    list[str] tcErrs = [];

    // VeriLang no separa "semantica" de TypePal -> la dejamos en true.
    bool semOk = true;
    list[str] semErrs = [];

    // 5) Codigo formateado (pretty printer)
    // ── TODO(A): PrettyPrinter.rsc hoy hace println(...). Refactorizar para que
    //    una funcion RETORNE str (p.ej. `str prettyPrintStr(Module m)`) y aqui:
    //        str codigoFormateado = prettyPrintStr(m);
    str codigoFormateado = "";

    // 6) Volcado del AST a JSON en disco (lo pide literalmente el enunciado)
    // ── TODO(A): serializar el AST a un .json y escribirlo, p.ej.:
    //        loc out = file[extension="ast.json"];
    //        writeFile(out, astToJson(m));   // astToJson lo defines tu
    //    (si optan por el flujo "Kotlin lee el archivo .json" en vez de stdout,
    //     este es el punto donde se genera ese archivo).

    // 7) Todo OK -> emitir JSON. `info` (modulo + usings) va en output por ahora.
    //    Acuerdo de equipo (CONTRATO_JSON.md): si quieren un campo propio
    //    `modulos`, A lo agrega aqui y B lo agrega en RunResult.kt + la UI.
    println(jsonResult(true, modName, true, tcOk, semOk, tcErrs, semErrs, info, "", codigoFormateado, resumen));
}
