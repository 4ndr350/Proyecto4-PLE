module verilang::TypePalCheck

// ─── Resumensito y meta a lograr  ──────────────────────────────────────
//   4) Agregar Int, Bool, Char, String como tipos primitivos, y un defspace como un nuevo tipo definido por usuario
//   5) Se verifica que los tipos usados en defvar, defoperator y defer correspondan a un espacio definido
//   6) Los identificadores usados en defexpression deben haber sido declarados con defvar
// ─────────────────────────────────────────────────────────────────────────────

extend analysis::typepal::TypePal;

import verilang::Syntax;
import ParseTree;
import IO;
import String;
import List;
import Set;

// ─── Roles ───────────────────────────────────────────────────────────────────

data IdRole
  = spaceId()      
  | varId()        
  | opId()         
  | relId()        
  ;

// ─── Tipos abstractos ────────────────────────────────────────────────────────
// Punto 4: tipos primitivos y el tipo definido por usuario

data AType
  = intType()
  | boolType()
  | charType()
  | stringType()
  | spaceType(str name)   
  | unknownType()
  ;

str prettyAType(intType())         = "Int";
str prettyAType(boolType())        = "Bool";
str prettyAType(charType())        = "Char";
str prettyAType(stringType())      = "String";
str prettyAType(spaceType(str n))  = n;
str prettyAType(unknownType())     = "?";

// ─── Helper ──────────────────────────────────────────────────────────────────

private bool isPrimitive(str name) =
    name == "Int" || name == "Bool" || name == "Char" || name == "String";

private AType nameToAType(str name) {
    switch (name) {
        case "Int":    return intType();
        case "Bool":   return boolType();
        case "Char":   return charType();
        case "String": return stringType();
        default:       return spaceType(name);
    }
}

// ─── Collect rules ───────────────────────────────────────────────────────────

void collect(current: (DefMod) `defmodule <AnyId _> <Using* _> <Funcion* fs> end`,
             Collector c) {
    collect(fs, c);
}

// registra el nombre del espacio
void collect(current: (Funcion) `<DefSpace ds>`, Collector c) {
    collect(ds, c);
}

void collect(current: (DefSpace) `defspace <AnyId sid> end`, Collector c) {
    c.define("<sid>", spaceId(), sid, defType(spaceType("<sid>")));
}

void collect(current: (DefSpace) `defspace <AnyId sid> \< <AnyId _> end`, Collector c) {
    c.define("<sid>", spaceId(), sid, defType(spaceType("<sid>")));
}

// defoperator: registra nombre y verifica tipos de la cadena
void collect(current: (Funcion) `<DefOp dop>`, Collector c) {
    collect(dop, c);
}

void collect(current: (DefOp) `defoperator <AnyId oid> : <CadenaType ct> end`, Collector c) {
    c.define("<oid>", opId(), oid, defType(unknownType()));
    collectCadena(ct, c);
}

void collect(current: (DefOp) `defoperator <AnyId oid> : <CadenaType ct> <Atributos _> end`, Collector c) {
    c.define("<oid>", opId(), oid, defType(unknownType()));
    collectCadena(ct, c);
}

// registrar nombre y verifica tipos de la cadena
void collect(current: (Funcion) `<DefRel drl>`, Collector c) {
    collect(drl, c);
}

void collect(current: (DefRel) `defer <AnyId rid> : <CadenaType ct> end`, Collector c) {
    c.define("<rid>", relId(), rid, defType(unknownType()));
    collectCadena(ct, c);
}

void collect(current: (DefRel) `defer <AnyId rid> : <CadenaType ct> <Atributos _> end`, Collector c) {
    c.define("<rid>", relId(), rid, defType(unknownType()));
    collectCadena(ct, c);
}

// Punto 5: cada AnyId en la cadena de tipos debe ser primitivo o un defspace
private void collectCadena(CadenaType ct, Collector c) {
    visit (ct) {
        case AnyId aid: {
            str name = "<aid>";
            if (!isPrimitive(name)) {
                c.use(aid, {spaceId()});
            }
        }
    }
}

// registra variables y verifica tipos
void collect(current: (Funcion) `<DefVar dv>`, Collector c) {
    collect(dv, c);
}

void collect(current: (DefVar) `defvar <{VarDecl ","}+ decls> end`, Collector c) {
    for (VarDecl d <- decls) {
        collect(d, c);
    }
}

// declaracion con tipo anotado
void collect(current: (VarDecl) `<AnyId n> : <AnyId t>`, Collector c) {
    str typeName = "<t>";
    c.define("<n>", varId(), n, defType(nameToAType(typeName)));
    // si no es primitivo, el tipo debe existir como defspace
    if (!isPrimitive(typeName)) {
        c.use(t, {spaceId()});
    }
}


void collect(current: (Funcion) `<DefRule _>`, Collector c) { }


void collect(current: (Funcion) `<DefEx de>`, Collector c) {
    collect(de, c);
}

void collect(current: (DefEx) `defexpression <DefExBody body> end`, Collector c) {
    collect(body, c);
}

void collect(current: (DefEx) `defexpression <DefExBody body> <Atributos _> end`, Collector c) {
    collect(body, c);
}

void collect(current: (DefExBody) `<Expresion e>`, Collector c) {
    collect(e, c);
}

void collect(current: (Expresion) `<Primaria p>`, Collector c) {
    collect(p, c);
}
void collect(current: (Expresion) `<Expresion l> or <Primaria r>`, Collector c) {
    collect(l, c); collect(r, c);
}
void collect(current: (Expresion) `<Expresion l> and <Primaria r>`, Collector c) {
    collect(l, c); collect(r, c);
}
void collect(current: (Expresion) `<Expresion l> =\> <Primaria r>`, Collector c) {
    collect(l, c); collect(r, c);
}
void collect(current: (Expresion) `<Expresion l> ≡ <Primaria r>`, Collector c) {
    collect(l, c); collect(r, c);
}

void collect(current: (Primaria) `neg <Primaria p>`, Collector c) {
    collect(p, c);
}
void collect(current: (Primaria) `<Cuantificador q>`, Collector c) {
    collect(q, c);
}
void collect(current: (Primaria) `<Operador op>`, Collector c) {
    collect(op, c);
}
void collect(current: (Primaria) `<Numero _>`, Collector c) { }

// Punto 6: un id en expresion debe estar declarado como variable
void collect(current: (Primaria) `<AnyId i>`, Collector c) {
    c.use(i, {varId()});
}

void collect(current: (Primaria) `( <Expresion e> )`, Collector c) {
    collect(e, c);
}

// la variable cuantificada se define localmente
void collect(current: (Cuantificador) `forall <AnyId v> . <Primaria body>`, Collector c) {
    c.enterScope(current);
    c.define("<v>", varId(), v, defType(unknownType()));
    collect(body, c);
    c.leaveScope(current);
}

void collect(current: (Cuantificador) `forall <AnyId v> in <AnyId d> . <Primaria body>`, Collector c) {
    c.enterScope(current);
    c.define("<v>", varId(), v, defType(unknownType()));
    c.use(d, {spaceId()});
    collect(body, c);
    c.leaveScope(current);
}

void collect(current: (Cuantificador) `exists <AnyId v> . <Primaria body>`, Collector c) {
    c.enterScope(current);
    c.define("<v>", varId(), v, defType(unknownType()));
    collect(body, c);
    c.leaveScope(current);
}

void collect(current: (Cuantificador) `exists <AnyId v> in <AnyId d> . <Primaria body>`, Collector c) {
    c.enterScope(current);
    c.define("<v>", varId(), v, defType(unknownType()));
    c.use(d, {spaceId()});
    collect(body, c);
    c.leaveScope(current);
}

void collect(current: (Operador) `( <OpName _> <OperArg* args> )`, Collector c) {
    for (OperArg a <- args) collect(a, c);
}

 // Punto 6: un id en un argumento debe ser variable declarada
void collect(current: (OperArg) `<AnyId i>`, Collector c) {
    c.use(i, {varId()});
}
void collect(current: (OperArg) `<Numero _>`, Collector c) { }
void collect(current: (OperArg) `<Operador op>`, Collector c) {
    collect(op, c);
}
void collect(current: (OperArg) `( <Expresion e> )`, Collector c) {
    collect(e, c);
}

// ─── Construccion del TModel ──────────────────────────────────────────────────

public TModel tmodelFromTree(start[DefMod] pt) {
    DefMod tree = pt.top;
    Collector col = newCollector("verilangCollect", tree, tconfig());
    collect(tree, col);
    return newSolver(tree, col.run()).run();
}


// ─── Interfaz principal ────────────────────────────────────────────────────────

public void checkCode(str code, loc origin) {
    try {
        start[DefMod] pt = parse(#start[DefMod], code, origin);
        TModel tm = tmodelFromTree(pt);
        list[Message] msgs = getMessages(tm);
        if (msgs == []) {
            println("TypePal: Okis, funcionando bien.");
        } else {
            println("TypePal: <size(msgs)> mensaje(s):");
            for (Message m <- msgs) {
                println("  - <m>");
            }
        }
    } catch ParseError(loc l): {
        println("Error en: <l>");
    }
}