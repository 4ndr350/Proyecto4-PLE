# VeriLang — Proyecto 4 (PLE / ISIS-2111)

App de escritorio (Kotlin + Compose) que ejecuta archivos `.vl` de **VeriLang**
invocando el backend en **Rascal**. Reutiliza el lenguaje del Proyecto 3 y lo
corre desde el entorno Kotlin, mostrando: parser OK/FAIL (con el error de Rascal),
la lista de módulos del archivo, e información adicional (conteos, resumen).

## Estructura

```
verilang-project/
├── rascal-shell-stable.jar     ← PREREQUISITO: ponlo aquí (NO está en git)
├── META-INF/RASCAL.MF
├── src/verilang/               ← backend del lenguaje (lado Persona A)
│   ├── Syntax.rsc  AST.rsc  Parser.rsc
│   ├── PrettyPrinter.rsc  TypePalCheck.rsc
│   └── RunnerJson.rsc          ← puente Rascal→Kotlin (emite el JSON)
├── tests/                      ← archivos .vl de prueba
│   ├── minimal.vl  set.vl  types_ok.vl  types_errors.vl
│   └── parse_error.vl          ← caso negativo (error de sintaxis)
├── examples/expected/
│   └── set.expected.json       ← salida esperada (stub para Persona B)
├── docs/
│   └── division_trabajo.md     ← reparto A/B + cronograma
├── CONTRATO_JSON.md            ← el contrato entre Rascal y Kotlin (la "costura")
└── kotlin-app/                 ← GUI e integración (lado Persona B)
    └── src/main/kotlin/verilang/
        ├── Main.kt  ui/MainWindow.kt
        ├── service/VeriLangService.kt   ← invoca el jar de Rascal
        └── model/RunResult.kt           ← refleja el contrato JSON
```

## Prerrequisitos (tarea compartida, sesión 0)

1. **`rascal-shell-stable.jar`** en la raíz del repo. (Descárgalo de la fuente que
   indicó el curso; no se versiona, ver `.gitignore`.)
2. **Java** (JDK 11+).
3. **Gradle** instalado en el sistema: `gradle --version`
   - Mac: `brew install gradle` · Win/Linux: https://gradle.org/install/

## Cómo correr

Backend solo (útil para Persona A, sin tocar Kotlin):

```bash
java -jar rascal-shell-stable.jar verilang::RunnerJson tests/set.vl
# debe imprimir UN objeto JSON; valídalo con:  ... | jq .
```

App completa (desde `kotlin-app/`):

```bash
cd kotlin-app
gradle run
```

## Flujo de trabajo en git

- `main` → estable, solo merges revisados.
- `feat/rascal` → Persona A (todo lo de `src/verilang/`).
- `feat/kotlin` → Persona B (todo lo de `kotlin-app/`).
- La **costura** es `CONTRATO_JSON.md` + `RunResult.kt`. Si cambian una clave del
  JSON, se avisa y se actualiza en ambos lados en el mismo PR.

Primer push al remoto (cada quien con su repo de GitHub ya creado):

```bash
git remote add origin git@github.com:USUARIO/verilang-project.git
git push -u origin main
git push origin feat/rascal feat/kotlin
```

Detalle del reparto y cronograma: ver `docs/division_trabajo.md`.
