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
    println("Module: <m.name>");
    if (!isEmpty(m.usings)) {
        println("  Imports: <commaJoin(m.usings)>");
    }
    println("");

    list[Funcion] sps   = [ f | Funcion f <- m.funciones, defSpace(_, _) := f ];
    list[Funcion] ops   = [ f | Funcion f <- m.funciones, defOp(_, _, _) := f ];
    list[Funcion] rels  = [ f | Funcion f <- m.funciones, defRel(_, _, _) := f ];
    list[Funcion] rules = [ f | Funcion f <- m.funciones, defRule(_, _)   := f ];
    list[Funcion] exps  = [ f | Funcion f <- m.funciones, defEx(_, _)     := f ];
    int totalVars = (0 | it + size(ds) | defVar(list[VarDecl] ds) <- m.funciones);

    println("  --- Summary ---");
    println("  Spaces:      <size(sps)>");
    println("  Operators:   <size(ops)>");
    println("  Relations:   <size(rels)>");
    println("  Variables:   <totalVars>");
    println("  Rules:       <size(rules)>");
    println("  Expressions: <size(exps)>");
    println("");

    if (!isEmpty(sps)) {
        println("  --- Spaces ---");
        for (defSpace(str name, str supe) <- sps) {
            if (supe == "") println("    <name>");
            else            println("    <name>  \<  <supe>");
        }
        println("");
    }

    if (!isEmpty(ops)) {
        println("  --- Operators ---");
        for (defOp(str name, list[str] tc, list[Atributo] attrs) <- ops) {
            str atStr = ppAttrs(attrs);
            println("    <name>  :  <ppTypeChain(tc)>  (arity <size(tc) - 1>)<atStr>");
        }
        println("");
    }

    if (!isEmpty(rels)) {
        println("  --- Relations ---");
        for (defRel(str name, list[str] tc, list[Atributo] attrs) <- rels) {
            str atStr = ppAttrs(attrs);
            println("    <name>  :  <ppTypeChain(tc)>  (arity <size(tc) - 1>)<atStr>");
        }
        println("");
    }

    if (totalVars > 0) {
        println("  --- Variables ---");
        map[str, list[str]] byType = ();
        for (defVar(list[VarDecl] decls) <- m.funciones, varDecl(str nm, str tp) <- decls) {
            if (tp in byType) byType[tp] += [nm];
            else              byType[tp]  = [nm];
        }
        for (str tp <- byType) {
            println("    <tp>  :  <commaJoin(byType[tp])>");
        }
        println("");
    }

    if (!isEmpty(rules)) {
        println("  --- Rules ---");
        for (defRule(Operador lhs, Operador rhs) <- rules) {
            println("    <ppOper(lhs)>  →  <ppOper(rhs)>");
        }
        println("");
    }

    if (!isEmpty(exps)) {
        println("  --- Expressions ---");
        int idx = 1;
        for (defEx(expresion(Expresion expr), list[Atributo] attrs) <- exps) {
            if (size(exps) > 1) println("  [<idx>]");
            if (!isEmpty(attrs)) {
                str atLine = ppAttrs(attrs);
                println("  <atLine>");
            }
            printExpr(expr, 1);
            idx += 1;
        }
        println("");
    }
}

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
