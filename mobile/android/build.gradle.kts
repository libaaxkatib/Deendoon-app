allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// file_picker's own android/build.gradle skips applying the classic
// `org.jetbrains.kotlin.android` plugin on AGP9+, assuming AGP9's built-in
// Kotlin support is active project-wide. It isn't here — only :app opts into
// it explicitly (see app/build.gradle.kts's `kotlin { }` block) — so
// file_picker's Kotlin sources never compile and the generated plugin
// registrant fails with "cannot find symbol". The Kotlin Gradle Plugin must
// be applied during configuration (not from `afterEvaluate` — its lifecycle
// manager rejects a later apply), so this runs unconditionally for this one
// named subproject, scoped narrowly to avoid touching other plugin modules
// (package_info_plus, pdfx, etc.) that already apply Kotlin correctly
// themselves.
//
// `compilerOptions.jvmTarget` (not `jvmToolchain(17)`) mirrors exactly what
// app/build.gradle.kts already does for :app — it sets the target bytecode
// version using whatever JDK is already running the Gradle daemon.
// `jvmToolchain(17)` instead asks Gradle to locate/auto-provision a
// registered JDK 17 toolchain, which fails on this machine (no JDK 17
// toolchain registered, no download repository configured) even though the
// running daemon itself is JDK 17-capable — the same daemon :app's build
// already compiles under successfully.
subprojects {
    if (project.name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")

        afterEvaluate {
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                compilerOptions {
                    jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                }
            }
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
