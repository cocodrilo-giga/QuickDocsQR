package com.example.yandexdiskqr.presentation

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.navigation.NavController
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.ui.setupWithNavController
import com.example.yandexdiskqr.R
import com.google.android.material.bottomnavigation.BottomNavigationView
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {

    private lateinit var navController: NavController
    private val viewModel: MainViewModel by viewModels() // Ваш ViewModel для обработки OAuth

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Настройка NavController
        val navHostFragment = supportFragmentManager.findFragmentById(R.id.nav_host_fragment) as NavHostFragment
        navController = navHostFragment.navController

        // Настройка BottomNavigationView с NavController
        val bottomNav = findViewById<BottomNavigationView>(R.id.bottom_nav)
        bottomNav.setupWithNavController(navController)

        handleAuthIntent(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        handleAuthIntent(intent)
    }

    private fun handleAuthIntent(intent: Intent?) {
        intent?.data?.let { uri ->
            // Проверка, что это наш redirect_uri
            if (uri.scheme == "ydiskqr" && uri.host == "auth") {
                val code = uri.getQueryParameter("code")
                if (code != null) {
                    // Обменяйте код на токен
                    lifecycleScope.launch {
                        viewModel.exchangeCodeForToken(code)
                    }
                } else {
                    // Обработка ошибки: код не найден
                    val error = uri.getQueryParameter("error")
                    // Обработайте ошибку по необходимости
                }
            }
        }
    }
}
