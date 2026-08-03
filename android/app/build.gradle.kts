// Imported rather than written as `java.util.Properties`: inside an
// application build script `java` resolves to Gradle's own `java`
// extension accessor, which shadows the package and fails with
// "Unresolved reference 'util'".
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Optional upload key, read from android/key.properties.
//
// Android will not install an APK over one signed with a different key -
// the member gets "App not installed" and has to uninstall first, losing
// their local state. Flutter's template signs release builds with the
// *debug* keystore, and CI generates a fresh debug keystore on every
// run, so consecutive releases would each be signed by a different key
// and no update would ever install cleanly.
//
// So: if a real keystore is configured, use it. If not, fall back to the
// debug key as before, because a template has to build for someone who
// has just cloned it and set nothing up. The release workflow writes
// this file from repository secrets when they exist; README says how.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasUploadKey = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.yokedchurch.yoked_church_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yokedchurch.yoked_church_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("upload") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // See the note at the top of this file: the debug key is the
            // fallback for an unconfigured clone, not the intended way to
            // ship. Every release built without an upload key is signed by
            // a different key, and Android refuses to install one over
            // another.
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
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
