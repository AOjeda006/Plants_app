import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // F7-054 / decisión #170: el plugin com.google.gms.google-services se
    // aplica CONDICIONALMENTE más abajo, solo si existe `google-services.json`.
    // Permite builds release sin Firebase real (modo mock — push deshabilitado
    // pero el resto de la app funciona) cuando el desarrollador aún no ha
    // ejecutado `flutterfire configure`.
}

// Aplicación condicional del plugin Google Services: requiere
// `google-services.json` en android/app/. Si no está, la app arranca sin
// push real y `Firebase.initializeApp()` falla silenciosamente (try/catch
// en main.dart) — el resto del proyecto sigue funcionando.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// F7-059 / decisión #176: carga `android/key.properties` (gitignored) si existe.
// Contiene `storePassword`, `keyPassword`, `keyAlias` y `storeFile` apuntando
// al keystore generado por el desarrollador con `keytool`. Si no existe, los
// builds release caen al keystore debug (con un warning) — útil para CI sin
// claves disponibles.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tfg.plants.plants_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.tfg.plants.plants_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Solo se registra `release` si hay key.properties; si no, los
        // build types release caerán al fallback debug.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias      = keystoreProperties["keyAlias"]      as String?
                keyPassword   = keystoreProperties["keyPassword"]   as String?
                storeFile     = (keystoreProperties["storeFile"]    as String?)?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // F7-059 / decisión #176: firmar con keystore propio si existe
            // key.properties; en su ausencia, mantener firma debug para que
            // `flutter run --release` siga funcionando en máquinas que no
            // tienen las claves de producción.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            // F7-059 / decisión #177: minificación R8/ProGuard desactivada.
            // APK más grande (~30-50MB) pero garantizado funcional sin
            // riesgo de romper Firebase u otras librerías que usan
            // reflection. En producción real se activaría con reglas
            // ProGuard específicas.
            isMinifyEnabled    = false
            isShrinkResources  = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
