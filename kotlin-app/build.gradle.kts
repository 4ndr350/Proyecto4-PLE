import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    kotlin("jvm") version "1.9.22"
    id("org.jetbrains.compose") version "1.6.0"
    kotlin("plugin.serialization") version "1.9.22"
}

// TODO: cambia "verilang" por el nombre de tu lenguaje (en minúsculas, sin espacios)
group = "verilang"
version = "1.0.0"

repositories {
    mavenCentral()
    maven("https://maven.pkg.jetbrains.space/public/p/compose/dev")
    google()
}

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.material3)
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-swing:1.8.0")
}

compose.desktop {
    application {
        // TODO: si renombraste el paquete, actualiza aquí también (ej. "verilang.MainKt")
        mainClass = "verilang.MainKt"
        nativeDistributions {
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Deb)
            // TODO: cambia el packageName por el nombre de tu lenguaje
            packageName = "VeriLang"
            packageVersion = "1.0.0"
        }
    }
}
