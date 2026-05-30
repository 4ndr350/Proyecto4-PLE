package verilang.service

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import verilang.model.RunResult
import java.io.File
import java.util.concurrent.TimeUnit

class VeriLangService {

    // PONER EN false CUANDO EL BACKEND RASCAL ESTÉ LISTO
    private val USE_STUB: Boolean = true

    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

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
            val output = executeRascal(filePath)
            val jsonStr = extractJson(output)
                ?: return@withContext RunResult(error = "Rascal no produjo JSON válido:\n$output")
            json.decodeFromString<RunResult>(jsonStr)
        } catch (e: Exception) {
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

        if (process.exitValue() != 0 && stdout.isBlank())
            throw RuntimeException("Error de Rascal (exit ${process.exitValue()}):\n$stderr")

        return stdout
    }

    private fun extractJson(output: String): String? {
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
                if (esc)                { esc = false; continue }
                if (c == '\\' && inStr) { esc = true; continue }
                if (c == '"')           { inStr = !inStr; continue }
                if (!inStr) {
                    if (c == '{') depth++
                    else if (c == '}') { depth--; if (depth == 0) { end = i; break } }
                }
            }
            if (end != -1) {
                val candidate = clean.substring(brace, end + 1)
                try {
                    val parsed = Json.parseToJsonElement(candidate)
                    if (parsed is kotlinx.serialization.json.JsonObject && parsed.containsKey("success"))
                        return candidate
                } catch (_: Exception) {}
            }
            start = brace + 1
        }
        return null
    }
}
