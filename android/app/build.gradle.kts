plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
val hasKeyProperties = keyPropertiesFile.exists()
if (hasKeyProperties) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.woosh.ride"
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
        applicationId = "com.woosh.ride"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val storeFilePath = keyProperties["storeFile"] as String?
            if (hasKeyProperties && !storeFilePath.isNullOrEmpty()) {
                keyAlias = keyProperties["keyAlias"] as String?
                keyPassword = keyProperties["keyPassword"] as String?
                storeFile = file(storeFilePath)
                storePassword = keyProperties["storePassword"] as String?
            } else {
                val debugSigning = getByName("debug")
                keyAlias = debugSigning.keyAlias
                keyPassword = debugSigning.keyPassword
                storeFile = debugSigning.storeFile
                storePassword = debugSigning.storePassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
