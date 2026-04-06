plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bizos.bizos_x_pro"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bizos.bizos_x_pro"
        // Specific minSdk 21 to support latest file_picker and other core packages
        minSdk = flutter.minSdkVersion
        multiDexEnabled = true
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Optimization for Windows APK discovery
tasks.whenTaskAdded {
    if (name.contains("assembleRelease")) {
        doLast {
            val buildApkDir = File("${project.projectDir}/build/outputs/apk/release")
            val flutterApkDir = File("${project.rootDir}/../build/app/outputs/flutter-apk")
            if (buildApkDir.exists()) {
                flutterApkDir.mkdirs()
                buildApkDir.listFiles()?.forEach { file ->
                    if (file.name.endsWith(".apk")) {
                        file.copyTo(File(flutterApkDir, file.name), overwrite = true)
                    }
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
