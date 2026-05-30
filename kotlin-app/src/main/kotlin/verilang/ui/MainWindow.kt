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
import androidx.compose.ui.text.font.FontWeight
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
    var uiError  by remember { mutableStateOf("") }

    val bg      = Color(0xFF1E1E1E)
    val surface = Color(0xFF2D2D2D)
    val text    = Color(0xFFEEEEEE)
    val green   = Color(0xFF4CAF50)
    val red     = Color(0xFFEF5350)
    val orange  = Color(0xFFFF9800)
    val blue    = Color(0xFF90CAF9)
    val gray    = Color(0xFF9E9E9E)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(bg)
            .padding(24.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        Text(
            "VeriLang Runner",
            color = text,
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold
        )

        // ── Fila: campo de ruta + botones ───────────────────────────────────
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            OutlinedTextField(
                value = filePath,
                onValueChange = { filePath = it },
                label = { Text("Archivo .vl", color = Color.Gray) },
                modifier = Modifier.weight(1f),
                singleLine = true,
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = text, unfocusedTextColor = text,
                    focusedBorderColor = blue, unfocusedBorderColor = Color.Gray
                ),
                textStyle = LocalTextStyle.current.copy(fontFamily = FontFamily.Monospace)
            )

            Button(
                onClick = {
                    val chooser = JFileChooser().apply {
                        fileFilter = FileNameExtensionFilter("Archivos VeriLang (*.vl)", "vl")
                        currentDirectory = File(System.getProperty("user.home"))
                    }
                    if (chooser.showOpenDialog(null) == JFileChooser.APPROVE_OPTION)
                        filePath = chooser.selectedFile.absolutePath
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF455A64))
            ) { Text("Buscar") }

            Button(
                onClick = {
                    uiError = ""
                    scope.launch {
                        running = true
                        result = try {
                            service.run(filePath.trim())
                        } catch (e: Exception) {
                            RunResult(error = "Error al invocar el backend: ${e.message}")
                        }
                        running = false
                    }
                },
                enabled = filePath.isNotBlank() && !running,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF1565C0))
            ) {
                if (running)
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        color = text,
                        strokeWidth = 2.dp
                    )
                else
                    Text("Correr")
            }
        }

        // ── Error de la UI (no del backend) ────────────────────────────────
        if (uiError.isNotBlank()) {
            Text(uiError, color = red, fontFamily = FontFamily.Monospace, fontSize = 13.sp)
        }

        // ── Panel de resultados ─────────────────────────────────────────────
        result?.let { r ->
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(surface, RoundedCornerShape(8.dp))
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // Nombre del módulo — encabezado prominente
                if (r.module.isNotBlank()) {
                    Text(
                        r.module,
                        color = blue,
                        fontSize = 20.sp,
                        fontWeight = FontWeight.SemiBold,
                        fontFamily = FontFamily.Monospace
                    )
                }

                // Chips de estado
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    StatusChip("Parser",     r.parseOk,     green, red)
                    StatusChip("Type Check", r.typeCheckOk, green, orange)
                }

                // Error del parser (solo cuando parseOk = false)
                if (!r.parseOk && r.error.isNotBlank()) {
                    SectionBox("Error de parser", r.error, red)
                }

                // Error general (cuando parseOk = true pero hay otro error)
                if (r.parseOk && r.error.isNotBlank()) {
                    SectionBox("Error", r.error, red)
                }

                // Errores de tipos (lista, uno por línea)
                if (r.typeErrors.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Errores de tipos", color = orange, fontSize = 13.sp)
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(orange.copy(alpha = 0.08f), RoundedCornerShape(4.dp))
                                .padding(10.dp)
                                .heightIn(max = 200.dp)
                                .verticalScroll(rememberScrollState())
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                r.typeErrors.forEach { errLine ->
                                    Text(
                                        errLine,
                                        color = Color(0xFFEEEEEE),
                                        fontFamily = FontFamily.Monospace,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        }
                    }
                }

                // Resumen del módulo — línea destacada
                if (r.resumen.isNotBlank()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFF37474F), RoundedCornerShape(4.dp))
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                    ) {
                        Text(
                            r.resumen,
                            color = gray,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 12.sp
                        )
                    }
                }

                // Módulos (output): una línea por item
                if (r.output.isNotEmpty()) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Módulos", color = green, fontSize = 13.sp)
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(green.copy(alpha = 0.07f), RoundedCornerShape(4.dp))
                                .padding(10.dp)
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                r.output.forEach { line ->
                                    Text(
                                        line,
                                        color = Color(0xFFEEEEEE),
                                        fontFamily = FontFamily.Monospace,
                                        fontSize = 13.sp
                                    )
                                }
                            }
                        }
                    }
                }

                // Errores semánticos (reservado)
                if (r.semanticErrors.isNotEmpty()) {
                    SectionBox("Errores semánticos", r.semanticErrors.joinToString("\n"), orange)
                }

                // Código formateado — monospace + scroll, oculto si vacío
                if (r.codigoFormateado.isNotBlank()) {
                    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                        Text("Código formateado", color = blue, fontSize = 13.sp)
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(blue.copy(alpha = 0.07f), RoundedCornerShape(4.dp))
                                .padding(10.dp)
                                .heightIn(max = 300.dp)
                                .verticalScroll(rememberScrollState())
                        ) {
                            Text(
                                r.codigoFormateado,
                                color = Color(0xFFEEEEEE),
                                fontFamily = FontFamily.Monospace,
                                fontSize = 12.sp
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun StatusChip(label: String, ok: Boolean, okColor: Color, failColor: Color) {
    val color = if (ok) okColor else failColor
    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.18f), RoundedCornerShape(4.dp))
            .padding(horizontal = 12.dp, vertical = 5.dp)
    ) {
        Text(
            "$label: ${if (ok) "OK" else "FAIL"}",
            color = color,
            fontSize = 13.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

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
            Text(
                content,
                color = Color(0xFFEEEEEE),
                fontFamily = FontFamily.Monospace,
                fontSize = 13.sp
            )
        }
    }
}
