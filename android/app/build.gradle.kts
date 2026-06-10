plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}


// Load secrets.properties file
def secretsProperties = new Properties()
def secretsFile = rootProject.file("secrets.properties")

// Cek apakah file secrets.properties ada
if (secretsFile.exists()) {
    secretsProperties.load(new FileInputStream(secretsFile))
    println "✅ secrets.properties loaded successfully"
} else {
    println "⚠️ secrets.properties not found. Google Maps API Key may not work."
}

android {

    namespace = "com.example.projektpm"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion

    compileOptions {

        // DESUGARING
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {

        // APPLICATION ID
        applicationId = "com.example.google_maps_in_flutter"

        // MIN SDK GOOGLE MAPS
        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName

        // MULTIDEX
        multiDexEnabled = true

      
        // Mengirim API key dari secrets.properties ke AndroidManifest.xml
        manifestPlaceholders = [
            mapsApiKey: secretsProperties.getProperty("MAPS_API_KEY", ""),
            // Format: "MAPS_API_KEY" adalah key di secrets.properties
            // "mapsApiKey" adalah placeholder di AndroidManifest.xml
        ]
    }

    buildTypes {

        release {

            signingConfig =
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    // DESUGARING LIBRARY
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.0.3"
    )
}