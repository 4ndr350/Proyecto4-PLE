module verilang::AstJson

import verilang::AST;
import String;
import List;

// ─── Public entry ──────────────────────────────────────────────────────────

public str astToJson(Module m) = moduleToJson(m);

// ─── Helpers ───────────────────────────────────────────────────────────────

private str esc(str s) =
    replaceAll(replaceAll(replaceAll(replaceAll(
        s, "\\", "\\\\"), "\"", "\\\""), "\n", "\\n"), "\t", "\\t");

private str jStr(str s)        = "\"<esc(s)>\"";
private str jBool(bool b)      = b ? "true" : "false";
private str jNum(real v)       = endsWith("<v>", ".0") ? "<v>"[0..-2] : "<v>";
private str jArr(list[str] xs) = "[<intercalate(",", xs)>]";
private str jObj(list[str] fields) = "{<intercalate(",", fields)>}";
private str jField(str k, str v)   = "\"<k>\":<v>";

// ─── Module ────────────────────────────────────────────────────────────────

private str moduleToJson(Module m) =
    jObj([
        jField("type",      jStr("module")),
        jField("name",      jStr(m.name)),
        jField("usings",    jArr([ jStr(u) | u <- m.usings ])),
        jField("funciones", jArr([ funcionToJson(f) | f <- m.funciones ]))
    ]);

// ─── Funcion ───────────────────────────────────────────────────────────────

private str funcionToJson(defSpace(str name, str sup)) =
    jObj([
        jField("type",       jStr("defSpace")),
        jField("name",       jStr(name)),
        jField("superSpace", jStr(sup))
    ]);

private str funcionToJson(defOp(str name, list[str] tc, list[Atributo] attrs)) =
    jObj([
        jField("type",      jStr("defOp")),
        jField("name",      jStr(name)),
        jField("typeChain", jArr([ jStr(t) | t <- tc ])),
        jField("attrs",     jArr([ attrToJson(a) | a <- attrs ]))
    ]);

private str funcionToJson(defRel(str name, list[str] tc, list[Atributo] attrs)) =
    jObj([
        jField("type",      jStr("defRel")),
        jField("name",      jStr(name)),
        jField("typeChain", jArr([ jStr(t) | t <- tc ])),
        jField("attrs",     jArr([ attrToJson(a) | a <- attrs ]))
    ]);

private str funcionToJson(defVar(list[VarDecl] decls)) =
    jObj([
        jField("type",  jStr("defVar")),
        jField("decls", jArr([ varDeclToJson(d) | d <- decls ]))
    ]);

private str funcionToJson(defRule(Operador lhs, Operador rhs)) =
    jObj([
        jField("type", jStr("defRule")),
        jField("lhs",  operToJson(lhs)),
        jField("rhs",  operToJson(rhs))
    ]);

private str funcionToJson(defEx(DefExBody body, list[Atributo] attrs)) =
    jObj([
        jField("type",  jStr("defEx")),
        jField("body",  defExBodyToJson(body)),
        jField("attrs", jArr([ attrToJson(a) | a <- attrs ]))
    ]);

// ─── VarDecl ───────────────────────────────────────────────────────────────

private str varDeclToJson(varDecl(str name, str tipo)) =
    jObj([ jField("name", jStr(name)), jField("tipo", jStr(tipo)) ]);

// ─── DefExBody ─────────────────────────────────────────────────────────────

private str defExBodyToJson(expresion(Expresion e)) =
    jObj([ jField("type", jStr("expresion")), jField("expr", exprToJson(e)) ]);

// ─── Expresion ─────────────────────────────────────────────────────────────

private str exprToJson(or(Expresion l, Expresion r)) =
    jObj([ jField("type", jStr("or")), jField("lhs", exprToJson(l)), jField("rhs", exprToJson(r)) ]);

private str exprToJson(and(Expresion l, Expresion r)) =
    jObj([ jField("type", jStr("and")), jField("lhs", exprToJson(l)), jField("rhs", exprToJson(r)) ]);

private str exprToJson(implies(Expresion l, Expresion r)) =
    jObj([ jField("type", jStr("implies")), jField("lhs", exprToJson(l)), jField("rhs", exprToJson(r)) ]);

private str exprToJson(eqv(Expresion l, Expresion r)) =
    jObj([ jField("type", jStr("eqv")), jField("lhs", exprToJson(l)), jField("rhs", exprToJson(r)) ]);

private str exprToJson(neg(Expresion e)) =
    jObj([ jField("type", jStr("neg")), jField("expr", exprToJson(e)) ]);

private str exprToJson(quantForall(str v, str d, Expresion body)) =
    jObj([ jField("type", jStr("forall")), jField("var", jStr(v)), jField("domain", jStr(d)), jField("body", exprToJson(body)) ]);

private str exprToJson(quantExists(str v, str d, Expresion body)) =
    jObj([ jField("type", jStr("exists")), jField("var", jStr(v)), jField("domain", jStr(d)), jField("body", exprToJson(body)) ]);

private str exprToJson(oper(Operador op)) =
    jObj([ jField("type", jStr("oper")), jField("op", operToJson(op)) ]);

private str exprToJson(idRef(str name)) =
    jObj([ jField("type", jStr("idRef")), jField("name", jStr(name)) ]);

private str exprToJson(numLit(real v)) =
    jObj([ jField("type", jStr("numLit")), jField("val", jNum(v)) ]);

private str exprToJson(paren(Expresion e)) =
    jObj([ jField("type", jStr("paren")), jField("expr", exprToJson(e)) ]);

// ─── Operador ──────────────────────────────────────────────────────────────

private str operToJson(operApp(str name, list[OperArg] args)) =
    jObj([
        jField("type",   jStr("operApp")),
        jField("opName", jStr(name)),
        jField("args",   jArr([ argToJson(a) | a <- args ]))
    ]);

private str argToJson(argId(str name))       = jObj([ jField("type", jStr("argId")),    jField("name", jStr(name)) ]);
private str argToJson(argNum(real v))         = jObj([ jField("type", jStr("argNum")),   jField("val",  jNum(v)) ]);
private str argToJson(argOper(Operador op))   = jObj([ jField("type", jStr("argOper")),  jField("op",   operToJson(op)) ]);
private str argToJson(argParen(Expresion e))  = jObj([ jField("type", jStr("argParen")), jField("expr", exprToJson(e)) ]);

// ─── Atributo ──────────────────────────────────────────────────────────────

private str attrToJson(attrSimple(str name))            = jObj([ jField("type", jStr("simple")), jField("name", jStr(name)) ]);
private str attrToJson(attrValId(str name, str v))      = jObj([ jField("type", jStr("valId")),  jField("name", jStr(name)), jField("val", jStr(v)) ]);
private str attrToJson(attrValNum(str name, real v))    = jObj([ jField("type", jStr("valNum")), jField("name", jStr(name)), jField("val", jNum(v)) ]);
private str attrToJson(attrValDash(str name))           = jObj([ jField("type", jStr("valDash")),jField("name", jStr(name)) ]);
