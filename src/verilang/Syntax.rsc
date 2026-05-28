module verilang::Syntax

// ─── Layout ────────────────────────────────────────────────────────────────

layout Layout = WhitespaceOrComment* !>> [\t\n\r\ ];

lexical WhitespaceOrComment
  = whitespace: [\t\n\r\ ]
  | comment:    "//" ![\n]* "\n"
  ;

// ─── Keywords ──────────────────────────────────────────────────────────────

keyword Keywords
  = "defmodule" | "using"    | "defspace"    | "defoperator"
  | "defvar"    | "defrule"  | "defexpression"| "defer"
  | "forall"    | "exists"   | "end"          | "in"
  | "and"       | "or"       | "neg"
  ;

// ─── Lexicals ──────────────────────────────────────────────────────────────

lexical Id
  = id: [a-z] [a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-]
  \ Keywords
  ;

// Capitalised identifiers (e.g. Set, Bool, Element)
lexical UId
  = uid: [A-Z] [a-zA-Z0-9\-]* !>> [a-zA-Z0-9\-]
  ;

// Any identifier (lower or upper case)
lexical AnyId
  = Id
  | UId
  ;

lexical Numero
  = numero: [0-9]+ ("." [0-9]+)?
  ;

// Operator-name terminals used inside parenthesised expressions
lexical OpName
  = opId:    Id
  | opUId:   UId
  | opPlus:  "+"
  | opMinus: "-" !>> [a-zA-Z0-9\-\>]   // avoid eating "->"
  | opPow:   "**"
  | opMul:   "*"
  | opDiv:   "/"
  | opMod:   "%"
  | opLeq:   "\<="
  | opGeq:   "\>="
  | opNeq:   "\<\>"
  | opLt:    "\<"  !>> "="
  | opGt:    "\>"  !>> "="
  | opImpl:  "=\>"
  | opEqq:   "≡"
  | opEq:    "="   !>> "\>"
  ;

// ─── Concrete Syntax ───────────────────────────────────────────────────────

start syntax DefMod
  = defmod: "defmodule" AnyId Using* Funcion* "end"
  ;

syntax Using
  = using: "using" AnyId
  ;

syntax Funcion
  = defspace:   DefSpace
  | defop:      DefOp
  | defvar:     DefVar
  | defrule:    DefRule
  | defex:      DefEx
  | defrel:     DefRel
  | atributos:  Atributos
  ;

syntax DefSpace
  = defspace: "defspace" AnyId ("\<" AnyId)? "end"
  ;

// Type chain:  A -> B -> C
syntax CadenaType
  = cadenaType: AnyId ("-\>" AnyId)+
  ;

syntax DefOp
  = defop: "defoperator" AnyId ":" CadenaType Atributos? "end"
  ;

syntax DefRel
  = defrel: "defer" AnyId ":" CadenaType Atributos? "end"
  ;

syntax DefVar
  = defvar: "defvar" {VarDecl ","}+ "end"
  ;

syntax VarDecl
  = varDecl: AnyId ":" AnyId
  ;

syntax DefRule
  = defrule: "defrule" Operador "-\>" Operador "end"
  ;

syntax DefEx
  = defex: "defexpression" DefExBody Atributos? "end"
  ;

syntax DefExBody
  = expresion: Expresion
  ;

// ─── Expressions ───────────────────────────────────────────────────────────

syntax Expresion
  = expr: Primaria
  | or:   Expresion "or"  Primaria
  | and:  Expresion "and" Primaria
  | impl: Expresion "=\>" Primaria
  | eqv:  Expresion "≡"   Primaria
  ;

syntax Primaria
  = neg:         "neg" Primaria
  | cuantif:     Cuantificador
  | operador:    Operador
  | idRef:       AnyId
  | numLit:      Numero
  | paren:       "(" Expresion ")"
  ;

syntax Cuantificador
  = forall: "forall" AnyId ("in" AnyId)? "." Primaria
  | exists: "exists" AnyId ("in" AnyId)? "." Primaria
  ;

// Parenthesised prefix application: ( opName arg* )
syntax Operador
  = oper: "(" OpName OperArg* ")"
  ;

syntax OperArg
  = argId:   AnyId
  | argNum:  Numero
  | argOper: Operador
  | argParen:"(" Expresion ")"
  ;

// ─── Attributes ────────────────────────────────────────────────────────────

syntax Atributos
  = attrs: "[" {Atributo ","}+ "]"
  ;

syntax Atributo
  = attrSimple:  AnyId
  | attrValId:   AnyId ":" AnyId
  | attrValNum:  AnyId ":" Numero
  | attrValDash: AnyId ":" "-"
  ;
