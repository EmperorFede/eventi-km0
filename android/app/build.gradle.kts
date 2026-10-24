import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chiave di firma delle versioni da installare sul telefono. Deve restare sempre la stessa:
// con una chiave diversa Android non accetta l'aggiornamento senza disinstallare (e perdere i dati).
val proprietaFirma = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "it.eventikm0.eventi_km0"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Richiesto da ota_update (aggiornamento automatico dell'app).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.eventikm0.eventi_km0"
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
        if (proprietaFirma.isNotEmpty()) {
            create("release") {
                keyAlias = proprietaFirma.getProperty("keyAlias")
                keyPassword = proprietaFirma.getProperty("keyPassword")
                storeFile = file(proprietaFirma.getProperty("storeFile"))
                storePassword = proprietaFirma.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Senza key.properties si firma con la chiave di debug (solo per prove sul PC).
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            // Niente ottimizzazione R8: shared_preferences chiama il codice Kotlin via JNI e R8
            // lo rinomina o lo toglie (l'app si bloccava all'avvio). Per un'app personale va bene così.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
