// TODO: si renombraste el paquete, cambia "verilang" por el nombre de tu lenguaje
package verilang.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import verilang.model.RunResult
import verilang.service.VeriLangService
import java.io.File
import javax.swing.JFileChooser
import javax.swing.filechooser.FileNameExtensionFilter

@Composable
fun MainWindow() {
    val service = remember { VeriLangService() }
    val scope   = rememberCoroutineScope()

    var filePath by remember { mutableStateOf("") }
    var result   by remember { mutableStateOf<RunResult?>(null) }
    var running  by remember { mutableStateOf(false) }

    // Colores del tema oscuro (puedes cambiarlos a gusto)
    val green   = Color(0xFF2E7D32)
    val red     = Color(0xFFC62828)
    val yellow  = Color(0xFFF57F17)
    val bg      = Color(0xFF1E1E1E)
    val surface = Color(0xFF2D2D2D)
    val text    = Color(0xFFEEEEEE)

    Column(
        modifier = Modifier.fillMaxSize().background(bg).padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // TODO: cambia el título por el nombre de tu lenguaje
        Text("VeriLang — Runner", color = text, fontSize = 22.sp)

        // Fila superior: campo de ruta, botón de seleccionar archivo, botón de correr
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = filePath,
                onValueChange = { filePath = it },
                // TODO: actualiza la etiqueta con la extensión de tu lenguaje (ej. "archivo .ml")
                label = { Text("Ruta del archivo fuente", color = Color.Gray) },
                modifier = Modifier.weight(1f),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = text, unfocusedTextColor = text,
                    focusedBorderColor = Color(0xFF90CAF9), unfocusedBorderColor = Color.Gray
                ),
                textStyle = LocalTextStyle.current.copy(fontFamily = FontFamily.Monospace)
            )

            Button(
                onClick = {
                    val chooser = JFileChooser().apply {
                        // TODO: cambia "ml" y la descripción por la extensión de tu lenguaje
                        fileFilter = FileNameExtensionFilter("Archivos de VeriLang (*.vl)", "vl")
                        currentDirectory = File(System.getProperty("user.home"))
                    }
                    if (chooser.showOpenDialog(null) == JFileChooser.APPROVE_OPTION)
                        filePath = chooser.selectedFile.absolutePath
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF455A64))
            ) {
                Text("Buscar")
            }

            Button(
                onClick = {
                    scope.launch {
                        running = true
                        result  = service.run(filePath.trim())
                        running = false
                    }
                },
                enabled = filePath.isNotBlank() && !running,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1565C0))
            ) {
                if (running)
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), color = text, strokeWidth = 2.dp)
                else
                    Text("Correr")
            }
        }

        // panel de resultados, aparece solo despueus de ejecutar
        result?.let { r ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(surface, RoundedCornerShape(8.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // statements de estado Parse / TypeCheck / semantica
                Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    StatusChip("Parse",     r.parseOk,     green, red)
                    StatusChip("Types",     r.typeCheckOk, green, yellow)
                    StatusChip("Semántica", r.semanticOk,  green, red)
                    if (r.module.isNotBlank())
                        Text("módulo: ${r.module}", color = Color(0xFF90CAF9), fontFamily = FontFamily.Monospace)
                }

                // resumen del AST 
                if (r.resumen.isNotBlank()) {
                    Text(r.resumen, color = Color(0xFF9E9E9E), fontFamily = FontFamily.Monospace, fontSize = 12.sp)
                }

                // error general 
                if (r.error.isNotBlank()) {
                    SectionBox("Error", r.error, red)
                }

                // errores de tipos
                if (r.typeErrors.isNotEmpty()) {
                    SectionBox("Errores de tipos", r.typeErrors.joinToString("\n"), yellow)
                }

                // errores semanticos
                if (r.semanticErrors.isNotEmpty()) {
                    SectionBox("Errores semánticos", r.semanticErrors.joinToString("\n"), yellow)
                }

                // pretty printer
                if (r.codigoFormateado.isNotBlank()) {
                    SectionBox("Código formateado", r.codigoFormateado, Color(0xFF90CAF9))
                }

                // salida del programa
                if (r.output.isNotEmpty()) {
                    SectionBox("Output", r.output.joinToString("\n"), green)
                }
            }
        }
    }
}

// Chip de estado coloreado (OK / FAIL)
@Composable
private fun StatusChip(label: String, ok: Boolean, okColor: Color, failColor: Color) {
    val color = if (ok) okColor else failColor
    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text("$label: ${if (ok) "OK" else "FAIL"}", color = color, fontSize = 12.sp)
    }
}

// Caja con título y contenido scrolleable
@Composable
private fun SectionBox(title: String, content: String, color: Color) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, color = color, fontSize = 13.sp)
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(color.copy(alpha = 0.07f), RoundedCornerShape(4.dp))
                .padding(10.dp)
                .heightIn(max = 200.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Text(content, color = Color(0xFFEEEEEE), fontFamily = FontFamily.Monospace, fontSize = 13.sp)
        }
    }
}
