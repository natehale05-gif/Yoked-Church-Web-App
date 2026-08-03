allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Compile file_picker's Kotlin.
//
// Without this the Android build fails with:
//
//     GeneratedPluginRegistrant.java: cannot find symbol
//     class FilePickerPlugin, location: package com.mr.flutter.plugin.filepicker
//
// file_picker 11.0.2's android/build.gradle skips applying the Kotlin
// plugin when AGP is 9 or newer, expecting AGP's built-in Kotlin to take
// over - but Flutter's template sets `android.builtInKotlin=false`, so
// nothing compiles the plugin's .kt sources and its main class simply
// does not exist. The generated registrant still references it, and the
// app fails to compile.
//
// Flutter's Gradle plugin would normally apply KGP to any subproject
// that doesn't, but it decides by scanning the build script text, and
// file_picker's `apply plugin: 'org.jetbrains.kotlin.android'` line is
// there - just inside an `if (!isAgp9OrAbove)` that never runs.
//
// So apply it here, by plugin id rather than through KGP's typed DSL -
// this script must keep compiling whether or not those types are on its
// classpath. The matching JVM-target relaxation is in gradle.properties,
// because file_picker also skips its own `kotlinOptions` block on AGP 9.
//
// Removable once file_picker handles AGP 9 - the symptom of it being
// removed too early is the compile error above, not silent breakage.
subprojects {
    if (project.name == "file_picker") {
        plugins.withId("com.android.library") {
            project.pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
