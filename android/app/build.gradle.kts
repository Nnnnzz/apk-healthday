plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.healthday_application"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17  // ✅ เปลี่ยนจาก 1_8
        targetCompatibility = JavaVersion.VERSION_17  // ✅ เปลี่ยนจาก 1_8
    }

    kotlinOptions {
        jvmTarget = "17"  // ✅ เปลี่ยนจาก '1.8' (single quote → double quote)
    }

    defaultConfig {
        applicationId = "com.example.healthday_application"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
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