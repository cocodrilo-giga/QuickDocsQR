#!/bin/bash

cd YandexDiskQR

# Создание директорий для UI
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/folders
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/scanner
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/viewer
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/navigation

# Создание основного класса приложения
cat > app/src/main/java/com/example/yandexdiskqr/YandexDiskQRApp.kt << 'EOL'
package com.example.yandexdiskqr

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class YandexDiskQRApp : Application()
EOL

# Создание MainActivity
cat > app/src/main/java/com/example/yandexdiskqr/presentation/MainActivity.kt << 'EOL'
package com.example.yandexdiskqr.presentation

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.ActivityMainBinding
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val navHostFragment = supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        val navController = navHostFragment.navController
        
        binding.bottomNav.setupWithNavController(navController)
    }
}
EOL

# Создание основного layout файла
cat > app/src/main/res/layout/activity_main.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.fragment.app.FragmentContainerView
        android:id="@+id/nav_host_fragment"
        android:name="androidx.navigation.fragment.NavHostFragment"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:defaultNavHost="true"
        app:layout_constraintBottom_toTopOf="@id/bottom_nav"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:navGraph="@navigation/nav_graph" />

    <com.google.android.material.bottomnavigation.BottomNavigationView
        android:id="@+id/bottom_nav"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:menu="@menu/bottom_nav_menu" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Создание навигационного графа
cat > app/src/main/res/navigation/nav_graph.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<navigation xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/nav_graph"
    app:startDestination="@id/foldersFragment">

    <fragment
        android:id="@+id/foldersFragment"
        android:name="com.example.yandexdiskqr.presentation.folders.FoldersFragment"
        android:label="@string/folders">
        <action
            android:id="@+id/action_folders_to_qr"
            app:destination="@id/qrGeneratorFragment" />
    </fragment>

    <fragment
        android:id="@+id/scannerFragment"
        android:name="com.example.yandexdiskqr.presentation.scanner.ScannerFragment"
        android:label="@string/scanner">
        <action
            android:id="@+id/action_scanner_to_viewer"
            app:destination="@id/viewerFragment" />
    </fragment>

    <fragment
        android:id="@+id/viewerFragment"
        android:name="com.example.yandexdiskqr.presentation.viewer.ViewerFragment"
        android:label="@string/viewer">
        <argument
            android:name="folderPath"
            app:argType="string" />
    </fragment>

</navigation>
EOL

# Создание меню нижней навигации
mkdir -p app/src/main/res/menu
cat > app/src/main/res/menu/bottom_nav_menu.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<menu xmlns:android="http://schemas.android.com/apk/res/android">
    <item
        android:id="@+id/foldersFragment"
        android:icon="@drawable/ic_folder"
        android:title="@string/folders" />
    
    <item
        android:id="@+id/scannerFragment"
        android:icon="@drawable/ic_qr_scanner"
        android:title="@string/scanner" />
</menu>
EOL

# Создание файла строковых ресурсов
cat > app/src/main/res/values/strings.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">YandexDisk QR</string>
    <string name="folders">Папки</string>
    <string name="scanner">Сканер</string>
    <string name="viewer">Просмотр</string>
    <string name="generate_qr">Создать QR-код</string>
    <string name="scan_qr">Сканировать QR-код</string>
    <string name="error_loading_folder">Ошибка загрузки папки</string>
    <string name="error_scanning">Ошибка сканирования</string>
    <string name="error_generating_qr">Ошибка создания QR-кода</string>
</resources>
EOL

echo "Main application components created successfully!"