#!/bin/bash

cd YandexDiskQR

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

# Создание фрагментов
cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersFragment.kt << 'EOL'
package com.example.yandexdiskqr.presentation.folders

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.yandexdiskqr.databinding.FragmentFoldersBinding
import com.example.yandex