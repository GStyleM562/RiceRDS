import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release vía android/key.properties (NO versionado). Si no existe,
// se firma con la clave de debug para que `flutter run --release` siga funcionando.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.riceprotocolstudio.nodehack_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ID de aplicación PERMANENTE una vez publicado. (Producción usa nodeprotocol.)
        applicationId = "com.riceprotocolstudio.nodehack_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val storeFilePath = keyProperties["storeFile"] as? String ?: ""
    if (keyPropertiesFile.exists() && storeFilePath.isNotEmpty()) {
        signingConfigs {
            create("release") {
                keyAlias = keyProperties["keyAlias"] as? String ?: ""
                keyPassword = keyProperties["keyPassword"] as? String ?: ""
                storeFile = file(storeFilePath)
                storePassword = keyProperties["storePassword"] as? String ?: ""
            }
        }
    }

    buildTypes {
        release {
            // Usa la firma de release si hay key.properties; si no, la de debug.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
