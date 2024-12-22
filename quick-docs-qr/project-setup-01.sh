#!/bin/bash

# Создание базовой структуры проекта
PROJECT_ROOT="YandexDiskQR"
PACKAGE_PATH="com/example/yandexdiskqr"

# Создание корневой директории проекта
mkdir -p $PROJECT_ROOT
cd $PROJECT_ROOT

# Создание базовых файлов проекта
echo "plugins {
    id 'com.android.application' version '8.1.0'
    id 'org.jetbrains.kotlin.android' version '1.9.0'
    id 'kotlin-kapt'
    id 'dagger.hilt.android.plugin' version '2.48'
}" > build.gradle.kts

echo "pluginManagement {
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
        maven { url 'https://sdk.yandex.net/maven' }
    }
}" > settings.gradle.kts

# Создание структуры папок приложения
mkdir -p app/src/main/java/$PACKAGE_PATH/{data,domain,presentation,di}
mkdir -p app/src/main/res/{layout,values,drawable}

# Создание build.gradle для модуля app
echo "plugins {
    id 'com.android.application'
    id 'kotlin-android'
    id 'kotlin-kapt'
    id 'dagger.hilt.android.plugin'
}

android {
    namespace 'com.example.yandexdiskqr'
    compileSdk 34

    defaultConfig {
        applicationId 'com.example.yandexdiskqr'
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName '1.0'
    }

    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    buildFeatures {
        viewBinding true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
}

dependencies {
    // Android core dependencies
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // Lifecycle components
    implementation 'androidx.lifecycle:lifecycle-viewmodel-ktx:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-livedata-ktx:2.7.0'
    implementation 'androidx.lifecycle:lifecycle-runtime-ktx:2.7.0'
    
    // Coroutines
    implementation 'org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3'
    
    // Hilt
    implementation 'com.google.dagger:hilt-android:2.48'
    kapt 'com.google.dagger:hilt-compiler:2.48'
    
    // Navigation
    implementation 'androidx.navigation:navigation-fragment-ktx:2.7.6'
    implementation 'androidx.navigation:navigation-ui-ktx:2.7.6'
    
    // Яндекс.Диск SDK
    implementation 'com.yandex.android:disk-sdk:1.0'
    
    // QR code scanning
    implementation 'com.google.mlkit:barcode-scanning:17.2.0'
    implementation 'androidx.camera:camera-camera2:1.3.1'
    implementation 'androidx.camera:camera-lifecycle:1.3.1'
    implementation 'androidx.camera:camera-view:1.3.1'
    
    // QR code generation
    implementation 'com.google.zxing:core:3.5.2'
}" > app/build.gradle.kts

# Создание манифеста приложения
mkdir -p app/src/main/
echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\"
    package=\"com.example.yandexdiskqr\">

    <uses-permission android:name=\"android.permission.INTERNET\" />
    <uses-permission android:name=\"android.permission.CAMERA\" />
    
    <application
        android:name=\".YandexDiskQRApp\"
        android:allowBackup=\"true\"
        android:icon=\"@mipmap/ic_launcher\"
        android:label=\"@string/app_name\"
        android:roundIcon=\"@mipmap/ic_launcher_round\"
        android:supportsRtl=\"true\"
        android:theme=\"@style/Theme.YandexDiskQR\">
        
        <activity
            android:name=\".presentation.MainActivity\"
            android:exported=\"true\">
            <intent-filter>
                <action android:name=\"android.intent.action.MAIN\" />
                <category android:name=\"android.intent.category.LAUNCHER\" />
            </intent-filter>
        </activity>
    </application>
</manifest>" > app/src/main/AndroidManifest.xml

echo "Project structure created successfully!"