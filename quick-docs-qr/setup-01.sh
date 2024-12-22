#!/bin/bash

# Создаем структуру проекта
mkdir -p app/src/main/java/com/example/yandexdiskqr/{data,domain,di,presentation}/{model,repository,usecase,auth,folders,scanner,viewer}
mkdir -p app/src/main/res/{drawable,layout,values,navigation,menu}

# Создаем и обновляем файлы сборки
cat > build.gradle.kts << 'EOL'
plugins {
    id("com.android.application") version "8.2.0"
    id("org.jetbrains.kotlin.android") version "1.9.21"
    id("kotlin-kapt")
    id("com.google.dagger.hilt.android") version "2.48.1"
}

android {
    namespace = "com.example.yandexdiskqr"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.yandexdiskqr"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    buildFeatures {
        viewBinding = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Android core dependencies
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    
    // Lifecycle components
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    
    // Hilt
    implementation("com.google.dagger:hilt-android:2.48.1")
    kapt("com.google.dagger:hilt-compiler:2.48.1")
    
    // Navigation
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.6")
    implementation("androidx.navigation:navigation-ui-ktx:2.7.6")
    
    // Яндекс.Диск SDK
    implementation("com.yandex.android:disk-rest-library-android:1.03")
    
    // QR code scanning
    implementation("com.google.mlkit:barcode-scanning:17.2.0")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    
    // QR code generation
    implementation("com.google.zxing:core:3.5.2")

    // SharedPreferences encryption
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
}
EOL

cat > settings.gradle.kts << 'EOL'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://maven.google.com") }
        maven { url = uri("https://sdk.yandex.net/maven") }
    }
}

rootProject.name = "YandexDiskQR"
include(":app")
EOL

# Делаем файл исполняемым
chmod +x 01_setup.sh
