#!/bin/bash

cd YandexDiskQR

# Создание AuthActivity
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/auth
cat > app/src/main/java/com/example/yandexdiskqr/presentation/auth/AuthActivity.kt << 'EOL'
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
EOL

# Создание AuthViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/auth/AuthViewModel.kt << 'EOL'
package com.example.yandexdiskqr.presentation.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.domain.usecase.GetAuthTokenUseCase
import com.example.yandexdiskqr.domain.usecase.SaveAuthTokenUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val getAuthTokenUseCase: GetAuthTokenUseCase,
    private val saveAuthTokenUseCase: SaveAuthTokenUseCase
) : ViewModel() {

    private val _authState = MutableLiveData<AuthState>()
    val authState: LiveData<AuthState> = _authState

    fun checkAuth() {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            getAuthTokenUseCase()
                .onSuccess { token ->
                    if (token.isNotEmpty()) {
                        _authState.value = AuthState.Authenticated
                    } else {
                        _authState.value = AuthState.Unauthenticated
                    }
                }
                .onFailure {
                    _authState.value = AuthState.Unauthenticated
                }
        }
    }

    fun exchangeCodeForToken(code: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            saveAuthTokenUseCase(code)
                .onSuccess {
                    _authState.value = AuthState.Authenticated
                }
                .onFailure { exception ->
                    _authState.value = AuthState.Error(exception.message ?: "Authentication failed")
                }
        }
    }
}
EOL

# Создание AuthState
cat > app/src/main/java/com/example/yandexdiskqr/presentation/auth/AuthState.kt << 'EOL'
package com.example.yandexdiskqr.presentation.auth

sealed class AuthState {
    object Loading : AuthState()
    object Authenticated : AuthState()
    object Unauthenticated : AuthState()
    data class Error(val message: String) : AuthState()
}
EOL

# Создание UseCase для авторизации
cat > app/src/main/java/com/example/yandexdiskqr/domain/usecase/GetAuthTokenUseCase.kt << 'EOL'
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.AuthRepository
import javax.inject.Inject

class GetAuthTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(): Result<String> = runCatching {
        authRepository.getAuthToken()
    }
}
EOL

cat > app/src/main/java/com/example/yandexdiskqr/domain/usecase/SaveAuthTokenUseCase.kt << 'EOL'
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.AuthRepository
import javax.inject.Inject

class SaveAuthTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(code: String): Result<Unit> = runCatching {
        authRepository.exchangeCodeForToken(code)
    }
}
EOL

# Создание AuthRepository
cat > app/src/main/java/com/example/yandexdiskqr/domain/repository/AuthRepository.kt << 'EOL'
package com.example.yandexdiskqr.domain.repository

interface AuthRepository {
    suspend fun getAuthToken(): String
    suspend fun exchangeCodeForToken(code: String)
    suspend fun clearAuth()
}
EOL

# Создание layout для AuthActivity
cat > app/src/main/res/layout/activity_auth.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <ImageView
        android:id="@+id/logoImage"
        android:layout_width="120dp"
        android:layout_height="120dp"
        android:src="@drawable/ic_launcher_foreground"
        app:layout_constraintBottom_toTopOf="@id/titleText"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintVertical_chainStyle="packed" />

    <TextView
        android:id="@+id/titleText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="@string/app_name"
        android:textAppearance="?attr/textAppearanceHeadline5"
        app:layout_constraintBottom_toTopOf="@id/signInButton"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/logoImage" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/signInButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="32dp"
        android:text="@string/sign_in_with_yandex"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/titleText" />

    <ProgressBar
        android:id="@+id/progressBar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Добавление строк для авторизации
cat >> app/src/main/res/values/strings.xml << 'EOL'
    <string name="sign_in_with_yandex">Войти через Яндекс</string>
    <string name="auth_error">Ошибка авторизации</string>
EOL

# Обновление AndroidManifest.xml для поддержки авторизации
cat > app/src/main/AndroidManifest.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.yandexdiskqr">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    
    <application
        android:name=".YandexDiskQRApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.YandexDiskQR">
        
        <activity
            android:name=".presentation.auth.AuthActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
            
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:host="auth"
                    android:scheme="ydiskqr" />
            </intent-filter>
        </activity>
        
        <activity
            android:name=".presentation.MainActivity"
            android:exported="false" />
    </application>
</manifest>
EOL

echo "Auth components created successfully!"