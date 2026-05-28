# División de trabajo — Proyecto 4 VeriLang

Corte por capas, unidas por `CONTRATO_JSON.md`. Esa frontera permite trabajar en
paralelo: A prueba Rascal por terminal y B desarrolla la UI contra
`examples/expected/set.expected.json` hasta que el JSON real esté listo.

## Sesión 0 — juntos (antes de separarse)
- [ ] Conseguir `rascal-shell-stable.jar` y ponerlo en la raíz.
- [ ] Instalar Gradle (`gradle --version`) y Java.
- [ ] Confirmar que el backend compila: `java -jar rascal-shell-stable.jar verilang::RunnerJson tests/set.vl`
- [ ] Confirmar que `gradle run` levanta la ventana (aunque aún no conecte).
- [ ] Leer juntos `CONTRATO_JSON.md` y cerrar las claves.
- [ ] Crear el repo en GitHub, `git push`, y trabajar en ramas `feat/rascal` y `feat/kotlin`.

> Nota: este entorno no tenía el jar de Rascal ni Gradle, así que el "compila/corre"
> NO se pudo verificar al armar la base. La sesión 0 es justamente para confirmarlo.

## Persona A — Lado Rascal (`src/verilang/`, rama `feat/rascal`)
Ya está hecho: módulos del P3 migrados + `RunnerJson.rsc` parsea y emite JSON válido.
Falta (marcado `TODO(A)` en `RunnerJson.rsc`):
- [ ] **Type check real**: enganchar `tmodelFromTree` + `getMessages` → llenar
      `typeCheckOk` y `typeErrors`. (Paso 4 del Runner; código sugerido en comentarios.)
- [ ] **Pretty printer que retorna texto**: refactorizar `PrettyPrinter.rsc` para que
      exista `str prettyPrintStr(Module m)` (hoy hace `println`), y usarlo en
      `codigoFormateado`. (Paso 5.)
- [ ] **Dump del AST a `.json`** en disco: `writeFile(file[extension="ast.json"], astToJson(m))`. (Paso 6.)
- [ ] Verificar los 5 casos de `tests/` (incluido `parse_error.vl` → debe dar `parseOk:false`).
- [ ] Es el **dueño del contrato**: cualquier cambio de clave se coordina con B.

## Persona B — Lado Kotlin (`kotlin-app/`, rama `feat/kotlin`)
Ya está hecho: paquete renombrado a `verilang`, `VeriLangService` apunta a
`verilang::RunnerJson`, file chooser `.vl`, títulos. La UI ya muestra parse/tipos/
módulo/resumen/errores.
Falta:
- [ ] Confirmar la ruta del `rascal-shell-stable.jar` desde `kotlin-app/` (sube un nivel).
- [ ] Probar el pipeline real contra cada `.vl` y manejar bien el caso FAIL (mostrar el
      `error` de Rascal de forma legible).
- [ ] Mejorar la presentación de la **lista de módulos** (hoy llega en `output`). Si se
      acuerda el campo `modulos`, agregarlo en `RunResult.kt` y renderizarlo aparte.
- [ ] (Opcional) Mostrar el `codigoFormateado` y el resumen con buen formato cuando A los entregue.
- [ ] Redactar la sección "cómo correr / capturas" del documento de entrega.

## Cronograma (sesiones relativas — ajustar al deadline real)

| Sesión | A (Rascal)                                   | B (Kotlin)                                  |
|--------|----------------------------------------------|---------------------------------------------|
| 0      | (juntos) jar + Gradle + contrato + repo      | (juntos)                                    |
| 1      | Type check real (`typeErrors`/`typeCheckOk`) | `gradle run` contra el stub JSON            |
| 2      | PrettyPrinter → retorna str (`codigoFormateado`) | Pulir UI: parse FAIL + error de Rascal  |
| 3      | Dump AST a `.json`                           | Lista de módulos / campo `modulos`          |
| 4      | (juntos) integración end-to-end OK y FAIL    | (juntos)                                    |
| 5      | (juntos) documento + zip de entrega          | (juntos)                                    |

## Cómo no pisarse
- A nunca toca `kotlin-app/`; B nunca toca `src/verilang/`. La única zona común es el
  contrato (se edita en PR conjunto).
- B desarrolla contra `examples/expected/set.expected.json` mientras A termina.
- Validar el JSON de A con `jq` antes de cablear nada en Kotlin.
