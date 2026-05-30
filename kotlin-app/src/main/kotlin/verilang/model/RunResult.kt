package verilang.model

import kotlinx.serialization.Serializable

/**
 * aca representa el resultado que devuelve Rascal en formato JSON
 *
 * IMPORTANTE: los nombres de los campos aquí deben coincidir Exactamente
 * con las claves del JSON que produce tu módulo RunnerJson.rsc en Rascal
 *
 * campos obligatorios que RunnerJson.rsc debe incluir:
 *   - success      > true si todo corrió sin errores
 *   - parseOk      > true si el parsing fue exitoso
 *   - typeCheckOk  > true si el type checking fue exitoso 
 *   - semanticOk   > true si las reglas semánticas pasaron
 *
 * Campos opcionales (si tu lenguaje no los usa, simplemente no los incluyas
 * en el JSON de Rascal y aquí quedarán vacíos por defecto):
 *   - module:  nombre del módulo procesado
 *   - typeErrors: lista de mensajes de error de tipos
 *   - semanticErrors: lista de mensajes de error semántico
 *   - output: lista de líneas de salida del programa
 *   - error: mensaje de error general (excepciones, etc etc)
 *   - codigoFormateado: resultado del pretty printer 
 *   - resumen: resumen del AST 
 */
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
