package verilang.service

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import verilang.model.RunResult
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Servicio que invoca Rascal como subproceso y devuelve el resultado parseado.
 *
 * Estructura esperada del proyecto:
 *   verilang-project/
 *   ├── rascal-shell-stable.jar
 *   ├── src/verilang/RunnerJson.rsc
 *   └── kotlin-app/   ← esta app
 */
class VeriLangService {

    // ── PONER EN false CUANDO A TERMINE EL BACKEND ──────────────────────────
    // Con true, run() devuelve el stub JSON en vez de invocar el jar de Rascal.
    private val USE_STUB: Boolean = true
    // ────────────────────────────────────────────────────────────────────────

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    // sube un nivel desde kotlin-app/ para llegar a la raíz del proyecto
    private val projectRoot: File by lazy {
        val cwd = File(System.getProperty("user.dir"))
        val candidate = cwd.resolve("../rascal-shell-stable.jar")
        if (candidate.exists()) cwd.resolve("..").canonicalFile
        else {
            val alt = cwd.parentFile
            if (alt?.resolve("rascal-shell-stable.jar")?.exists() == true) alt
            else cwd.resolve("..").canonicalFile
        }
    }

    private val rascalJar: File get() = projectRoot.resolve("rascal-shell-stable.jar")
    private val srcDir: File get() = projectRoot.resolve("src")

    
    private fun loadStub(): RunResult {
        val stubFile = projectRoot.resolve("examples/expected/set.expected.json")
        if (!stubFile.exists())
            return RunResult(error = "Stub no encontrado en: ${stubFile.absolutePath}")
        return json.decodeFromString<RunResult>(stubFile.readText())
    }

    suspend fun run(filePath: String): RunResult = withContext(Dispatchers.IO) {
        if (USE_STUB) return@withContext loadStub()
        try {
            println("[VeriLangService] Ejecutando Rascal...")
            println("[VeriLangService] archivo : $filePath")
            println("[VeriLangService] jar     : ${rascalJar.absolutePath}")
            println("[VeriLangService] src     : ${srcDir.absolutePath}")

            val t0 = System.currentTimeMillis()
            val output = executeRascal(filePath)
            println("[VeriLangService] tiempo  : ${System.currentTimeMillis() - t0} ms")
            println("[VeriLangService] stdout  : ${output.length} chars")

            val jsonStr = extractJson(output)
            if (jsonStr == null) {
                println("[VeriLangService] ERROR: no se encontró JSON en la salida de Rascal")
                return@withContext RunResult(error = "Rascal no produjo JSON válido:\n$output")
            }

            json.decodeFromString<RunResult>(jsonStr)
        } catch (e: Exception) {
            println("[VeriLangService] excepción: ${e.message}")
            e.printStackTrace()
            RunResult(error = e.message ?: "Error desconocido")
        }
    }

    private fun executeRascal(filePath: String): String {
        if (!rascalJar.exists())
            throw RuntimeException("No se encontró rascal-shell-stable.jar en ${rascalJar.absolutePath}")
        if (!srcDir.exists())
            throw RuntimeException("No se encontró el directorio src/ en ${srcDir.absolutePath}")

        val cmd = listOf(
            "java",
            "-Dfile.encoding=UTF-8",
            "-Drascal.projectPath=${srcDir.absolutePath}",
            "-jar", rascalJar.absolutePath,
            "verilang::RunnerJson",
            filePath
        )

        val process = ProcessBuilder(cmd)
            .directory(srcDir)
            .redirectErrorStream(false)
            .start()
        process.outputStream.close()

        // leemos stdout y stderr en hilos separados para evitar deadlocks
        val stdoutFuture = java.util.concurrent.Executors.newSingleThreadExecutor()
            .submit<String> { process.inputStream.bufferedReader().readText() }
        val stderrFuture = java.util.concurrent.Executors.newSingleThreadExecutor()
            .submit<String> { process.errorStream.bufferedReader().readText() }

        val finished = process.waitFor(180, TimeUnit.SECONDS)
        if (!finished) {
            process.destroyForcibly()
            throw RuntimeException("Rascal tardó más de 180s y fue detenido")
        }

        val stdout = stdoutFuture.get()
        val stderr = stderrFuture.get()

        println("--- STDERR (${stderr.length} chars) ---")
        if (stderr.isNotBlank()) println(stderr)
        println("--- exit code: ${process.exitValue()} ---")

        if (process.exitValue() != 0 && stdout.isBlank())
            throw RuntimeException("Error de Rascal (exit ${process.exitValue()}):\n$stderr")

        return stdout
    }

    
    //Extrae el primer objeto JSON válido que contenga la clave "success"
    //de la salida de Rascal 
     
    private fun extractJson(output: String): String? {
        // elimina códigos de color ANSI que rascasl a veces imprime
        val clean = output
            .replace(Regex("\\x1b\\[[^a-zA-Z]*[a-zA-Z]"), "")
            .replace(Regex("\\x1b[^\\[\\x1b]"), "")

        var start = 0
        while (start < clean.length) {
            val brace = clean.indexOf('{', start)
            if (brace == -1) break
            var depth = 0; var inStr = false; var esc = false; var end = -1
            for (i in brace until clean.length) {
                val c = clean[i]
                if (esc)              { esc = false; continue }
                if (c == '\\' && inStr) { esc = true; continue }
                if (c == '"')         { inStr = !inStr; continue }
                if (!inStr) {
                    if (c == '{') depth++
                    else if (c == '}') { depth--; if (depth == 0) { end = i; break } }
                }
            }
            if (end != -1) {
                val candidate = clean.substring(brace, end + 1)
                try {
                    val parsed = Json.parseToJsonElement(candidate)
                    // Buscamos el JSON que tenga "success", el que produjo RunnerJson.rsc
                    if (parsed is kotlinx.serialization.json.JsonObject && parsed.containsKey("success"))
                        return candidate
                } catch (_: Exception) {}
            }
            start = brace + 1
        }
        return null
    }
}
