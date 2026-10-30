import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de producción: android/key.properties (NO se versiona; plantilla en key.properties.example).
// Una compilación RELEASE (apk o appbundle) FALLA si la firma no es válida: nunca se firma un release
// con la llave de depuración. Las compilaciones debug y profile no cambian.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val camposFirma = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val problemaFirmaRelease: String? = run {
    if (!keystorePropertiesFile.exists()) {
        return@run "falta android/key.properties (cópielo de android/key.properties.example y complételo)"
    }
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
    val faltan = camposFirma.filter { (keystoreProperties.getProperty(it) ?: "").isBlank() }
    if (faltan.isNotEmpty()) return@run "android/key.properties no define: ${faltan.joinToString()}"
    if (camposFirma.any { keystoreProperties.getProperty(it) == "CAMBIAR" }) {
        return@run "android/key.properties todavía tiene los valores de ejemplo (CAMBIAR)"
    }
    val almacen = file(keystoreProperties.getProperty("storeFile"))
    if (!almacen.isFile) return@run "no existe el almacén de llaves indicado en storeFile: ${almacen.path}"
    null
}

android {
    namespace = "com.example.vigilancia_durazno"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // PENDIENTE DEL PROPIETARIO: definir el identificador definitivo (p. ej. el dominio de la
        // organización al revés) ANTES de la primera publicación; después no se puede cambiar.
        applicationId = "com.example.vigilancia_durazno"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (problemaFirmaRelease == null) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin firma válida no se asigna ninguna: la tarea verificarFirmaRelease detiene el build.
            if (problemaFirmaRelease == null) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

// Se ejecuta antes de cualquier tarea del release (preReleaseBuild): si la firma no es válida,
// la compilación se detiene con el motivo. No afecta a debug ni a profile.
val verificarFirmaRelease = tasks.register("verificarFirmaRelease") {
    val problema = problemaFirmaRelease
    doLast {
        if (problema != null) {
            throw GradleException(
                "SIGAT: no se puede compilar el release sin firma de producción: $problema. " +
                    "Las compilaciones debug (flutter run, flutter build apk --debug) no la necesitan.",
            )
        }
    }
}
tasks.configureEach {
    if (name == "preReleaseBuild") dependsOn(verificarFirmaRelease)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
