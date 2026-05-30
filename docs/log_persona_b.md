# Log Persona B — Proyecto 4 VeriLang

## PASO 0 — Resumen de lectura inicial

1. La app es Kotlin + Compose Desktop: Kotlin 1.9.22, Compose 1.6.0, serialización 1.6.3, coroutines 1.8.0.
2. El contrato define 11 claves exactas en RunResult.kt — ya están todas implementadas y coinciden con CONTRATO_JSON.md.
3. VeriLangService ya tiene `ignoreUnknownKeys = true` y `isLenient = true`; invoca Rascal como subproceso y extrae el JSON de stdout.
4. MainWindow ya tiene la estructura base (chips Parse/Types/Semántica, secciones de error/output/resumen/código), pero la presentación de módulos y errores puede mejorarse.
5. Trabajo en rama `feat/rascal` (debería ser `feat/kotlin`) — NO cambié de rama per instrucción. Usuario debe mover commits a `feat/kotlin` al volver (ver RESUMEN al final).

---

## TAREA 1 — Diagnóstico del proyecto

**Versiones:**
- Kotlin JVM: 1.9.22
- Compose Desktop: 1.6.0
- kotlinx-serialization-json: 1.6.3
- kotlinx-coroutines-core/swing: 1.8.0
- JDK target: no declarado explícitamente → usa default del plugin Kotlin 1.9.22 (JVM 8 bytecode por defecto, compatible con JDK 11+)

**Cómo correr:** `cd kotlin-app && gradle run`

**Observaciones:**
- No hay versiones sospechosas. Compose 1.6.0 + Kotlin 1.9.22 es un par estable.
- El mainClass está correctamente configurado como `verilang.MainKt`.
- No faltan dependencias para las tareas previstas.
- El filtro del file chooser ya usa `"vl"` ✓

**Decisión:** No se modificó nada. Solo diagnóstico.

---

## TAREA 2 — Modo STUB en VeriLangService.kt

**Qué hice:**
- Agregué la constante `USE_STUB = true` al inicio de la clase, con comentario claro.
- Agregué función `loadStub()` que lee `examples/expected/set.expected.json` desde la raíz del proyecto (un nivel arriba de `kotlin-app/`).
- En `run()`, si `USE_STUB` es true retorna `loadStub()` antes de tocar el subproceso.
- `ignoreUnknownKeys` ya estaba presente — no se tocó.

**Decisiones:**
- La ruta del stub usa `projectRoot` (ya calculado en el servicio), consistente con la lógica del jar.
- El stub falla con mensaje claro si el archivo no existe.

---

## TAREA 3 — Adaptar MainWindow.kt

**Qué hice:**
- Nombre del módulo movido a encabezado prominente (texto grande, color azul claro).
- Chips reorganizados: Parse (verde/rojo) y Type Check (verde/naranja) con labels en inglés per contrato.
- Sección "Error de Parser" aparece solo cuando `!parseOk` y `error` no está vacío.
- Sección "Errores de tipos" lista cada error en su propio Text (Column), no joinToString.
- Sección "Módulos" renderiza cada línea de `output` en un Text separado (Column).
- Sección "Código formateado" usa fuente monospace, scroll vertical, oculta si vacío ✓.
- Sección "Resumen" en línea destacada con color diferente.
- Chip "Semántica" eliminado de la vista principal (VeriLang lo pliega en TypePal → siempre true per contrato; no aporta información visual).

**Decisiones:**
- No inventé campos nuevos — todo viene de RunResult.kt existente.
- Eliminé el chip de Semántica porque era ruido visual para un campo que siempre es true en VeriLang.

---

## TAREA 4 — File chooser y manejo robusto de errores

**Qué hice:**
- Verificado: filtro ya usa `"vl"` ✓, cancel ya es seguro ✓, indicador de carga ya existe ✓.
- Añadí try/catch en la UI alrededor de `service.run()` — muestra mensaje de error legible (no stack trace) en el panel de resultados si el servicio lanza excepción.
- El mensaje de error queda en `result.error` via `RunResult(error = ...)`, así la UI lo muestra como cualquier otro error.

---

## RESUMEN PARA EL USUARIO

### Tareas completadas
- ✅ Tarea 1: Diagnóstico completo (sin modificaciones)
- ✅ Tarea 2: Modo STUB implementado — cambiar `USE_STUB = false` cuando A termine el backend
- ✅ Tarea 3: MainWindow adaptada a VeriLang con todas las secciones del contrato
- ✅ Tarea 4: Manejo de errores robusto en la UI

### Tareas saltadas / parciales
- Ninguna.

### Qué revisar manualmente al volver
1. **Rama equivocada**: los commits están en `feat/rascal`, no en `feat/kotlin`. Ejecutar:
   ```bash
   git log feat/rascal --oneline   # ver commits de B
   # luego cherry-pick a feat/kotlin o reorganizar
   ```
2. **Activar backend real**: cuando A confirme que el jar funciona, cambiar `USE_STUB = false` en `VeriLangService.kt`.
3. **Build con Gradle**: verificar que compila en el entorno real:
   ```bash
   cd kotlin-app
   gradle build
   gradle run
   ```
4. Chip de "Semántica" fue eliminado de la UI (era siempre true). Si el usuario quiere tenerlo de todas formas, se agrega fácilmente en MainWindow.kt línea del Row de chips.

### Comandos sugeridos para verificar
```bash
cd kotlin-app
gradle build          # verifica que compila
gradle run            # lanza la app con USE_STUB=true (no necesita el jar de Rascal)
```
