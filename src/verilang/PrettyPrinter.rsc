module verilang::PrettyPrinter

import verilang::AST;
import verilang::Parser;
import IO;
import String;
import List;
import Map;

// ─── Entry points ──────────────────────────────────────────────────────────

void run(loc file) {
    prettyPrint(parseModule(file));
}

void prettyPrint(Module m) {
    println(ppToStr(m));
}

public str prettyPrintStr(Module m) = ppToStr(m);

// ─── Str-returning core ────────────────────────────────────────────────────

str ppToStr(Module m) {
    str out = "Module: <m.name>\n";
    if (!isEmpty(m.usings)) {
        out += "  Imports: <commaJoin(m.usings)>\n";
    }
    out += "\n";

    list[Funcion] sps   = [ f | Funcion f <- m.funciones, defSpace(_, _) := f ];
    list[Funcion] ops   = [ f | Funcion f <- m.funciones, defOp(_, _, _) := f ];
    list[Funcion] rels  = [ f | Funcion f <- m.funciones, defRel(_, _, _) := f ];
    list[Funcion] rules = [ f | Funcion f <- m.funciones, defRule(_, _)   := f ];
    list[Funcion] exps  = [ f | Funcion f <- m.funciones, defEx(_, _)     := f ];
    int totalVars = (0 | it + size(ds) | defVar(list[VarDecl] ds) <- m.funciones);

    out += "  --- Summary ---\n";
    out += "  Spaces:      <size(sps)>\n";
    out += "  Operators:   <size(ops)>\n";
    out += "  Relations:   <size(rels)>\n";
    out += "  Variables:   <totalVars>\n";
    out += "  Rules:       <size(rules)>\n";
    out += "  Expressions: <size(exps)>\n\n";

    if (!isEmpty(sps)) {
        out += "  --- Spaces ---\n";
        for (defSpace(str name, str supe) <- sps) {
            if (supe == "") out += "    <name>\n";
            else            out += "    <name>  \<  <supe>\n";
        }
        out += "\n";
    }

    if (!isEmpty(ops)) {
        out += "  --- Operators ---\n";
        for (defOp(str name, list[str] tc, list[Atributo] attrs) <- ops) {
            str atStr = ppAttrs(attrs);
            out += "    <name>  :  <ppTypeChain(tc)>  (arity <size(tc) - 1>)<atStr>\n";
        }
        out += "\n";
    }

    if (!isEmpty(rels)) {
        out += "  --- Relations ---\n";
        for (defRel(str name, list[str] tc, list[Atributo] attrs) <- rels) {
            str atStr = ppAttrs(attrs);
            out += "    <name>  :  <ppTypeChain(tc)>  (arity <size(tc) - 1>)<atStr>\n";
        }
        out += "\n";
    }

    if (totalVars > 0) {
        out += "  --- Variables ---\n";
        map[str, list[str]] byType = ();
        for (defVar(list[VarDecl] decls) <- m.funciones, varDecl(str nm, str tp) <- decls) {
            if (tp in byType) byType[tp] += [nm];
            else              byType[tp]  = [nm];
        }
        for (str tp <- byType) {
            out += "    <tp>  :  <commaJoin(byType[tp])>\n";
        }
        out += "\n";
    }

    if (!isEmpty(rules)) {
        out += "  --- Rules ---\n";
        for (defRule(Operador lhs, Operador rhs) <- rules) {
            out += "    <ppOper(lhs)>  →  <ppOper(rhs)>\n";
        }
        out += "\n";
    }

    if (!isEmpty(exps)) {
        out += "  --- Expressions ---\n";
        int idx = 1;
        for (defEx(expresion(Expresion expr), list[Atributo] attrs) <- exps) {
            if (size(exps) > 1) out += "  [<idx>]\n";
            if (!isEmpty(attrs)) out += "  <ppAttrs(attrs)>\n";
            out += exprToStr(expr, 1);
            idx += 1;
        }
        out += "\n";
    }

    return out;
}

// ─── Expressions (str, indented) ───────────────────────────────────────────

str exprToStr(paren(Expresion e), int indent) = exprToStr(e, indent);

str exprToStr(quantForall(str v, str d, Expresion body), int indent) {
    str dom = d == "" ? "" : " ∈ <d>";
    return "<makeIndent(indent)>∀<v><dom> .\n" + exprToStr(body, indent + 1);
}

str exprToStr(quantExists(str v, str d, Expresion body), int indent) {
    str dom = d == "" ? "" : " ∈ <d>";
    return "<makeIndent(indent)>∃<v><dom> .\n" + exprToStr(body, indent + 1);
}

str exprToStr(Expresion e, int indent) =
    "<makeIndent(indent)><ppExprInline(e)>\n";

// ─── Type chain ────────────────────────────────────────────────────────────

str ppTypeChain(list[str] tc) {
    if (size(tc) <= 1) return isEmpty(tc) ? "?" : tc[0];
    list[str] dom = tc[0 .. size(tc) - 1];
    str cod       = tc[size(tc) - 1];
    return "<crossJoin(dom)> → <cod>";
}

// ─── Operators ─────────────────────────────────────────────────────────────

str ppOper(operApp(str name, list[OperArg] args)) {
    if (isEmpty(args)) return "(<name>)";
    list[str] parts = [ ppArg(a) | a <- args ];
    return "(<name> <spaceJoin(parts)>)";
}

str ppArg(argId(str name))       = name;
str ppArg(argNum(real v))        = ppNum(v);
str ppArg(argOper(Operador op))  = ppOper(op);
str ppArg(argParen(Expresion e)) = "(<ppExprInline(e)>)";

// ─── Attributes ────────────────────────────────────────────────────────────

str ppAttrs(list[Atributo] attrs) {
    if (isEmpty(attrs)) return "";
    list[str] parts = [ ppAttr(a) | a <- attrs ];
    return "  [<commaJoin(parts)>]";
}

str ppAttr(attrSimple(str name))         = name;
str ppAttr(attrValId(str name, str v))   = "<name>=<v>";
str ppAttr(attrValNum(str name, real v)) = "<name>=<ppNum(v)>";
str ppAttr(attrValDash(str name))        = "<name>=-";

// ─── Expressions (indented) ────────────────────────────────────────────────
// paren is stripped so quantifiers always land on their own indented line.

void printExpr(paren(Expresion e), int indent) {
    printExpr(e, indent);
}

void printExpr(quantForall(str v, str d, Expresion body), int indent) {
    str dom = d == "" ? "" : " ∈ <d>";
    println("<makeIndent(indent)>∀<v><dom> .");
    printExpr(body, indent + 1);
}

void printExpr(quantExists(str v, str d, Expresion body), int indent) {
    str dom = d == "" ? "" : " ∈ <d>";
    println("<makeIndent(indent)>∃<v><dom> .");
    printExpr(body, indent + 1);
}

void printExpr(Expresion e, int indent) {
    println("<makeIndent(indent)><ppExprInline(e)>");
}

// ─── Expressions (inline) ──────────────────────────────────────────────────

str ppExprInline(or(Expresion l, Expresion r))      = "<ppExprInline(l)> ∨ <ppExprInline(r)>";
str ppExprInline(and(Expresion l, Expresion r))     = "<ppExprInline(l)> ∧ <ppExprInline(r)>";
str ppExprInline(implies(Expresion l, Expresion r)) = "<ppExprInline(l)> ⇒ <ppExprInline(r)>";
str ppExprInline(eqv(Expresion l, Expresion r))     = "<ppExprInline(l)> ≡ <ppExprInline(r)>";
str ppExprInline(neg(Expresion e))                  = "¬<ppExprInline(e)>";
str ppExprInline(oper(Operador op))                 = ppOper(op);
str ppExprInline(idRef(str nm))                     = nm;
str ppExprInline(numLit(real v))                    = ppNum(v);
str ppExprInline(paren(Expresion e))                = "(<ppExprInline(e)>)";
str ppExprInline(quantForall(str v, str d, Expresion body)) {
    str dom = d == "" ? "" : " ∈ <d>";
    return "∀<v><dom> . <ppExprInline(body)>";
}
str ppExprInline(quantExists(str v, str d, Expresion body)) {
    str dom = d == "" ? "" : " ∈ <d>";
    return "∃<v><dom> . <ppExprInline(body)>";
}

// ─── Helpers ───────────────────────────────────────────────────────────────

str makeIndent(int n) = ("" | it + "  " | _ <- [0..n]);

str ppNum(real v) {
    str s = "<v>";
    return endsWith(s, ".0") ? s[0 .. size(s) - 2] : s;
}

str joinWith(list[str] xs, str sep) {
    if (isEmpty(xs)) return "";
    str r = xs[0];
    for (x <- xs[1..]) r += sep + x;
    return r;
}

str commaJoin(list[str] xs) = joinWith(xs, ", ");
str spaceJoin(list[str] xs) = joinWith(xs, " ");
str crossJoin(list[str] xs) = joinWith(xs, " × ");
