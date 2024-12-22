package com.example.yandexdiskqr.presentation.auth

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import com.example.yandexdiskqr.databinding.ActivityAuthBinding
import com.example.yandexdiskqr.di.Constants
import com.example.yandexdiskqr.presentation.MainActivity
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class AuthActivity : AppCompatActivity() {
    private lateinit var binding: ActivityAuthBinding
    private val viewModel: AuthViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupViews()
        observeViewModel()
        
        // Проверяем, есть ли сохраненный токен
        viewModel.checkAuth()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.data?.let { uri ->
            // Получаем код авторизации из URI
            uri.getQueryParameter("code")?.let { code ->
                viewModel.exchangeCodeForToken(code)
            }
        }
    }

    private fun setupViews() {
        binding.signInButton.setOnClickListener {
            startYandexAuth()
        }
    }

    private fun observeViewModel() {
        viewModel.authState.observe(this) { state ->
            when (state) {
                is AuthState.Authenticated -> startMainActivity()
                is AuthState.Error -> showError(state.message)
                AuthState.Unauthenticated -> binding.signInButton.isEnabled = true
                AuthState.Loading -> binding.signInButton.isEnabled = false
            }
        }
    }

    private fun startYandexAuth() {
        val authUri = Uri.parse("https://oauth.yandex.ru/authorize").buildUpon()
            .appendQueryParameter("response_type", "code")
            .appendQueryParameter("client_id", Constants.CLIENT_ID)
            .appendQueryParameter("redirect_uri", Constants.REDIRECT_URI)
            .build()

        val intent = Intent(Intent.ACTION_VIEW, authUri)
        startActivity(intent)
    }

    private fun startMainActivity() {
        startActivity(Intent(this, MainActivity::class.java))
        finish()
    }

    private fun showError(message: String) {
        // Показываем ошибку пользователю
    }
}
