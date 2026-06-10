import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}


// MEMBACA API KEY DARI SECRET.PROPERTIES

val secretsProperties = Properties()
val secretsFile = rootProject.file("secret.properties") 

if (secretsFile.exists()) {
    secretsProperties.load(FileInputStream(secretsFile))
    println("✅ secret.properties loaded successfully")
} else {
    println("⚠️ secret.properties not found. Google Maps API Key may not work.")
}

android {
    namespace = "com.example.projektpm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.google_maps_in_flutter"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // MANIFEST PLACEHOLDERS
        manifestPlaceholders.put(
            "mapsApiKey", secretsProperties.getProperty("MAPS_API_KEY", "")
        )
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}