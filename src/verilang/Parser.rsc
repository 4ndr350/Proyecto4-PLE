module verilang::Parser

import verilang::Syntax;
import verilang::AST;

import ParseTree;
import String;
import IO;

// ─── Entry point ───────────────────────────────────────────────────────────

Module parseModule(loc src) {
    Tree pt = parse(#start[DefMod], src);
    return implodeModule(pt.top);
}

Module parseModule(str src) {
    Tree pt = parse(#start[DefMod], src);
    return implodeModule(pt.top);
}

// ─── Module ────────────────────────────────────────────────────────────────

Module implodeModule((DefMod)`defmodule <AnyId mid> <Using* usings> <Funcion* funciones> end`) {
    str name         = "<mid>";
    list[str] us     = [ implodeUsing(u) | u <- usings ];
    list[Funcion] fs = [ implodefuncion(f) | f <- funciones ];
    return \module(name, us, fs);
}

// ─── Using ─────────────────────────────────────────────────────────────────

str implodeUsing((Using)`using <AnyId uid>`) = "<uid>";

// ─── Funcion dispatcher ────────────────────────────────────────────────────

Funcion implodefuncion((Funcion)`<DefSpace ds>`)   = implodeDefSpace(ds);
Funcion implodefuncion((Funcion)`<DefOp dop>`)     = implodeDefOp(dop);
Funcion implodefuncion((Funcion)`<DefVar dv>`)     = implodeDefVar(dv);
Funcion implodefuncion((Funcion)`<DefRule dr>`)    = implodeDefRule(dr);
Funcion implodefuncion((Funcion)`<DefEx de>`)      = implodeDefEx(de);
Funcion implodefuncion((Funcion)`<DefRel drl>`)    = implodeDefRel(drl);
Funcion implodefuncion((Funcion)`<Atributos at>`)  = defEx(expresion(idRef("__attrs__")), implodeAtributos(at));

// ─── DefSpace ──────────────────────────────────────────────────────────────

Funcion implodeDefSpace((DefSpace)`defspace <AnyId sid> end`) =
    defSpace("<sid>", "");

Funcion implodeDefSpace((DefSpace)`defspace <AnyId sid> \< <AnyId super> end`) =
    defSpace("<sid>", "<super>");

// ─── DefOp ─────────────────────────────────────────────────────────────────

Funcion implodeDefOp((DefOp)`defoperator <AnyId oid> : <CadenaType ct> end`) =
    defOp("<oid>", imploderCadena(ct), []);

Funcion implodeDefOp((DefOp)`defoperator <AnyId oid> : <CadenaType ct> <Atributos at> end`) =
    defOp("<oid>", imploderCadena(ct), implodeAtributos(at));

// ─── DefRel ────────────────────────────────────────────────────────────────

Funcion implodeDefRel((DefRel)`defer <AnyId rid> : <CadenaType ct> end`) =
    defRel("<rid>", imploderCadena(ct), []);

Funcion implodeDefRel((DefRel)`defer <AnyId rid> : <CadenaType ct> <Atributos at> end`) =
    defRel("<rid>", imploderCadena(ct), implodeAtributos(at));

// ─── CadenaType ────────────────────────────────────────────────────────────

list[str] imploderCadena(CadenaType ct) =
    [ trim(p) | p <- split("-\>", "<ct>"), trim(p) != "" ];

// ─── DefVar ────────────────────────────────────────────────────────────────

Funcion implodeDefVar((DefVar)`defvar <{VarDecl ","}+ decls> end`) =
    defVar([ implodeVarDecl(d) | d <- decls ]);

VarDecl implodeVarDecl((VarDecl)`<AnyId n> : <AnyId t>`) = varDecl("<n>", "<t>");

// ─── DefRule ───────────────────────────────────────────────────────────────

Funcion implodeDefRule((DefRule)`defrule <Operador lhs> -\> <Operador rhs> end`) =
    defRule(implodeOperador(lhs), implodeOperador(rhs));

// ─── DefEx ─────────────────────────────────────────────────────────────────

Funcion implodeDefEx((DefEx)`defexpression <DefExBody body> end`) =
    defEx(implodeDefExBody(body), []);

Funcion implodeDefEx((DefEx)`defexpression <DefExBody body> <Atributos at> end`) =
    defEx(implodeDefExBody(body), implodeAtributos(at));

DefExBody implodeDefExBody((DefExBody)`<Expresion e>`) =
    expresion(implodeExpr(e));

// ─── Expressions ───────────────────────────────────────────────────────────

Expresion implodeExpr((Expresion)`<Primaria p>`)                   = imploderPrim(p);
Expresion implodeExpr((Expresion)`<Expresion l> or <Primaria r>`)  = or(implodeExpr(l),  imploderPrim(r));
Expresion implodeExpr((Expresion)`<Expresion l> and <Primaria r>`) = and(implodeExpr(l), imploderPrim(r));
Expresion implodeExpr((Expresion)`<Expresion l> =\> <Primaria r>`) = implies(implodeExpr(l), imploderPrim(r));
Expresion implodeExpr((Expresion)`<Expresion l> ≡ <Primaria r>`)   = eqv(implodeExpr(l), imploderPrim(r));

Expresion imploderPrim((Primaria)`neg <Primaria p>`)        = neg(imploderPrim(p));
Expresion imploderPrim((Primaria)`<Cuantificador q>`)        = implodeCuant(q);
Expresion imploderPrim((Primaria)`<Operador op>`)            = oper(implodeOperador(op));
Expresion imploderPrim((Primaria)`<AnyId i>`)                = idRef("<i>");
Expresion imploderPrim((Primaria)`<Numero n>`)               = numLit(strToReal("<n>"));
Expresion imploderPrim((Primaria)`( <Expresion e> )`)        = paren(implodeExpr(e));

Expresion implodeCuant((Cuantificador)`forall <AnyId v> . <Primaria body>`) =
    quantForall("<v>", "", imploderPrim(body));

Expresion implodeCuant((Cuantificador)`forall <AnyId v> in <AnyId d> . <Primaria body>`) =
    quantForall("<v>", "<d>", imploderPrim(body));

Expresion implodeCuant((Cuantificador)`exists <AnyId v> . <Primaria body>`) =
    quantExists("<v>", "", imploderPrim(body));

Expresion implodeCuant((Cuantificador)`exists <AnyId v> in <AnyId d> . <Primaria body>`) =
    quantExists("<v>", "<d>", imploderPrim(body));

// ─── Operador ──────────────────────────────────────────────────────────────

Operador implodeOperador((Operador)`( <OpName op> <OperArg* args> )`) =
    operApp("<op>", [ implodeArg(a) | a <- args ]);

OperArg implodeArg((OperArg)`<AnyId i>`)          = argId("<i>");
OperArg implodeArg((OperArg)`<Numero n>`)          = argNum(strToReal("<n>"));
OperArg implodeArg((OperArg)`<Operador op>`)       = argOper(implodeOperador(op));
OperArg implodeArg((OperArg)`( <Expresion e> )`)   = argParen(implodeExpr(e));

// ─── Attributes ────────────────────────────────────────────────────────────

list[Atributo] implodeAtributos((Atributos)`[ <{Atributo ","}+ attrs> ]`) =
    [ implodeAttr(a) | a <- attrs ];

Atributo implodeAttr((Atributo)`<AnyId n>`)               = attrSimple("<n>");
Atributo implodeAttr((Atributo)`<AnyId n> : <AnyId v>`)   = attrValId("<n>", "<v>");
Atributo implodeAttr((Atributo)`<AnyId n> : <Numero v>`)  = attrValNum("<n>", strToReal("<v>"));
Atributo implodeAttr((Atributo)`<AnyId n> : -`)            = attrValDash("<n>");

// ─── Helpers ───────────────────────────────────────────────────────────────

real strToReal(str s) {
    if (/\./ := s) return toReal(s);
    return toReal(s + ".0");
}
