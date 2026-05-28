module verilang::AST

data Module = \module(str name, list[str] usings, list[Funcion] funciones);

// ─── Declaraciones fuertes  ──────────────────────────────────────────────────────────

data Funcion
  = defSpace(str name, str superSpace)
  | defOp(str name, list[str] typeChain, list[Atributo] attrs)
  | defRel(str name, list[str] typeChain, list[Atributo] attrs)
  | defVar(list[VarDecl] decls)
  | defRule(Operador lhs, Operador rhs)
  | defEx(DefExBody body, list[Atributo] attrs)
  ;

data VarDecl
  = varDecl(str name, str tipo)
  ;

data DefExBody
  = expresion(Expresion expr)
  ;

// ─── Expressions ───────────────────────────────────────────────────────────

data Expresion
  = or(Expresion lhs, Expresion rhs)
  | and(Expresion lhs, Expresion rhs)
  | implies(Expresion lhs, Expresion rhs)
  | eqv(Expresion lhs, Expresion rhs)
  | neg(Expresion expr)
  | quantForall(str var, str domain, Expresion body)  // domain = "" when absent
  | quantExists(str var, str domain, Expresion body)
  | oper(Operador op)
  | idRef(str name)
  | numLit(real val)
  | paren(Expresion expr)
  ;

data Operador
  = operApp(str opName, list[OperArg] args)
  ;

data OperArg
  = argId(str name)
  | argNum(real val)
  | argOper(Operador op)
  | argParen(Expresion expr)
  ;

// ─── Attributes ────────────────────────────────────────────────────────────

data Atributo
  = attrSimple(str name)
  | attrValId(str name, str strVal)
  | attrValNum(str name, real numVal)
  | attrValDash(str name)
  ;
