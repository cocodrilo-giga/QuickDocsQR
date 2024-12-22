#!/bin/bash

# Создаем основные директории
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/local
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/repository
mkdir -p app/src/main/java/com/example/yandexdiskqr/domain/repository
mkdir -p app/src/main/java/com/example/yandexdiskqr/di
mkdir -p app/src/main/res/values

# Исправляем build.gradle.kts
cat > ./app/build.gradle.kts << 'EOL'
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("kotlin-kapt")
    id("com.google.dagger.hilt.android")
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
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")
    
    // Navigation
    implementation("androidx.navigation:navigation-fragment-ktx:2.7.6")
    implementation("androidx.navigation:navigation-ui-ktx:2.7.6")
    
    // Яндекс.Диск SDK
    implementation("com.yandex.android:disk-sdk:1.0")
    
    // QR code scanning
    implementation("com.google.mlkit:barcode-scanning:17.2.0")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
    
    // QR code generation
    implementation("com.google.zxing:core:3.5.2")

    // DataStore
    implementation("androidx.datastore:datastore-preferences:1.0.0")
}
EOL

# Исправляем корневой build.gradle.kts
cat > ./build.gradle.kts << 'EOL'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
        classpath("com.google.dagger:hilt-android-gradle-plugin:2.48")
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
EOL

# Исправляем Constants.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/di/Constants.kt << 'EOL'
package com.example.yandexdiskqr.di

object Constants {
    // Замените на реальный CLIENT_ID из консоли разработчика Яндекс
    const val CLIENT_ID = "your_client_id_here"
    const val REDIRECT_URI = "ydiskqr://auth"
    const val OAUTH_URL = "https://oauth.yandex.ru/authorize"
    const val TOKEN_URL = "https://oauth.yandex.ru/token"
}
EOL

chmod +x ./gradlew
