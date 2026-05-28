# Contrato JSON (Rascal ↔ Kotlin)

Esta es **la costura del proyecto**. `RunnerJson.rsc` (Persona A) imprime exactamente
este objeto por stdout; `VeriLangService.kt` lo lee y lo deserializa en `RunResult.kt`
(Persona B). Las **claves deben coincidir carácter por carácter** en ambos lados.

Regla de oro: si cambian/añaden una clave, se hace en el **mismo PR** tocando los dos
lados (RunnerJson.rsc emite + RunResult.kt declara + MainWindow.kt la muestra).

## Esquema

```json
{
  "success":        true,        // bool  — true si no hubo errores fatales
  "module":         "Set",       // str   — nombre del defmodule del archivo
  "parseOk":        true,        // bool  — el parser de Rascal aceptó el archivo
  "typeCheckOk":    true,        // bool  — TypePal sin errores  (TODO(A))
  "semanticOk":     true,        // bool  — VeriLang lo pliega en TypePal → true
  "typeErrors":     [],          // [str] — mensajes de error de tipos (TODO(A))
  "semanticErrors": [],          // [str] — reservado
  "output":         ["Modulo: Set", "  using List"],  // [str] — lista de módulos + usings
  "error":          "",          // str   — error general / mensaje de ParseError de Rascal
  "codigoFormateado": "",        // str   — salida del PrettyPrinter (TODO(A))
  "resumen":        "Spaces: 1  |  Operators: 4  | ..."  // str — conteo de declaraciones
}
```

## Notas de diseño

- **VeriLang no se "ejecuta"** (es declarativo): no hay intérprete ni `runProgram`.
  Por eso `output` no es la salida de un programa, sino la **lista de módulos**
  (módulo + sus `using`) que pide el enunciado. `resumen` complementa con conteos.
- **Parser FAIL**: si el parse falla, `parseOk=false` y el mensaje del `ParseError`
  de Rascal va en `error`. La UI lo muestra como FAIL + el detalle.
- **Extensión opcional**: si el equipo decide un campo dedicado `"modulos": [str]`
  en vez de reutilizar `output`, se agrega en los dos lados a la vez. Gracias a
  `ignoreUnknownKeys=true` en Kotlin, A puede emitirlo antes de que B lo declare
  sin romper la app.
- **AST a archivo .json**: el enunciado pide "extract the AST into a JSON file".
  Eso lo genera A (TODO en `RunnerJson.rsc`, paso 6). El contrato de arriba es el
  resultado *del run*; el dump del AST es un archivo aparte (`<archivo>.ast.json`).
