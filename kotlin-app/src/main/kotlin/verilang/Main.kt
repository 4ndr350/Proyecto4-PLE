// TODO: si renombraste el paquete, cambia "verilang" por el nombre de tu lenguaje
package verilang

import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import verilang.ui.MainWindow

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        // TODO: cambia el título de la ventana por el nombre de tu lenguaje
        title = "VeriLang",
        state = rememberWindowState(width = 800.dp, height = 600.dp)
    ) {
        MainWindow()
    }
}
