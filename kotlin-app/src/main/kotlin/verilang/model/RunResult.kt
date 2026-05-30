package verilang.model

import kotlinx.serialization.Serializable

@Serializable
data class RunResult(
    val success: Boolean = false,
    val module: String = "",
    val parseOk: Boolean = false,
    val typeCheckOk: Boolean = false,
    val semanticOk: Boolean = false,
    val typeErrors: List<String> = emptyList(),
    val semanticErrors: List<String> = emptyList(),
    val output: List<String> = emptyList(),
    val error: String = "",
    val codigoFormateado: String = "",
    val resumen: String = ""
)
