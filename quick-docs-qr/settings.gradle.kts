pluginManagement {
    repositories {
        google()
        mavenCentral()
    }
    plugins {
        id("org.jetbrains.kotlin.android") version "1.9.24"
        id("org.jetbrains.kotlin.kapt") version "1.9.24" // Исправлено
        id("com.google.dagger.hilt.android") version "2.48"
        id("com.android.application") version "8.1.4"
    }
}

rootProject.name = "QuickDocsQR"
include(":app")
