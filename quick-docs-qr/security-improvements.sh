#!/bin/bash

# Создаем директории для безопасности
mkdir -p app/src/main/java/com/example/yandexdiskqr/security
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/local

# Создаем EncryptedStorage для безопасного хранения данных
cat > ./app/src/main/java/com/example/yandexdiskqr/security/EncryptedStorage.kt << 'EOL'
package com.example.yandexdiskqr.security

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EncryptedStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey: MasterKey by lazy {
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .setKeyGenParameterSpec(
                KeyGenParameterSpec.Builder(
                    "_androidx_security_master_key_",
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .build()
            )
            .build()
    }

    private val securePreferences: SharedPreferences by lazy {
        EncryptedSharedPreferences.create(
            context,
            "secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun saveString(key: String, value: String) {
        securePreferences.edit().putString(key, value).apply()
    }

    fun getString(key: String): String? {
        return securePreferences.getString(key, null)
    }

    fun remove(key: String) {
        securePreferences.edit().remove(key).apply()
    }

    fun clear() {
        securePreferences.edit().clear().apply()
    }
}
EOL

# Создаем AuthManager для управления авторизацией
cat > ./app/src/main/java/com/example/yandexdiskqr/security/AuthManager.kt << 'EOL'
package com.example.yandexdiskqr.security

import android.content.Context
import android.net.Uri
import com.example.yandexdiskqr.di.Constants
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val encryptedStorage: EncryptedStorage
) {
    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_TOKEN_EXPIRY = "token_expiry"
    }

    suspend fun saveTokens(accessToken: String, refreshToken: String, expiresIn: Long) {
        encryptedStorage.saveString(KEY_ACCESS_TOKEN, accessToken)
        encryptedStorage.saveString(KEY_REFRESH_TOKEN, refreshToken)
        encryptedStorage.saveString(KEY_TOKEN_EXPIRY, (System.currentTimeMillis() + expiresIn * 1000).toString())
    }

    fun getAccessToken(): String? {
        return encryptedStorage.getString(KEY_ACCESS_TOKEN)
    }

    fun getRefreshToken(): String? {
        return encryptedStorage.getString(KEY_REFRESH_TOKEN)
    }

    fun isTokenExpired(): Boolean {
        val expiry = encryptedStorage.getString(KEY_TOKEN_EXPIRY)?.toLongOrNull() ?: 0
        return System.currentTimeMillis() > expiry
    }

    fun clearAuth() {
        encryptedStorage.clear()
    }

    fun getAuthUrl(): String {
        return Uri.parse(Constants.OAUTH_URL)
            .buildUpon()
            .appendQueryParameter("response_type", "code")
            .appendQueryParameter("client_id", Constants.CLIENT_ID)
            .appendQueryParameter("redirect_uri", Constants.REDIRECT_URI)
            .build()
            .toString()
    }

    fun checkAuthState(): Flow<AuthState> = flow {
        val token = getAccessToken()
        when {
            token == null -> emit(AuthState.Unauthorized)
            isTokenExpired() -> {
                // Попытка обновить токен
                val refreshToken = getRefreshToken()
                if (refreshToken != null) {
                    emit(AuthState.NeedsRefresh(refreshToken))
                } else {
                    emit(AuthState.Unauthorized)
                }
            }
            else -> emit(AuthState.Authorized(token))
        }
    }
}
EOL

# Создаем AuthState для отслеживания состояния авторизации
cat > ./app/src/main/java/com/example/yandexdiskqr/security/AuthState.kt << 'EOL'
package com.example.yandexdiskqr.security

sealed class AuthState {
    data class Authorized(val token: String) : AuthState()
    data class NeedsRefresh(val refreshToken: String) : AuthState()
    object Unauthorized : AuthState()
}
EOL

# Обновляем AuthRepository
cat > ./app/src/main/java/com/example/yandexdiskqr/data/repository/AuthRepositoryImpl.kt << 'EOL'
package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.di.Constants
import com.example.yandexdiskqr.domain.model.TokenResponse
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.security.AuthManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val authManager: AuthManager
) : AuthRepository {

    override suspend fun getAuthToken(): String = withContext(Dispatchers.IO) {
        when (val state = authManager.checkAuthState().first()) {
            is AuthState.Authorized -> state.token
            is AuthState.NeedsRefresh -> refreshToken(state.refreshToken)
            AuthState.Unauthorized -> throw IllegalStateException("Unauthorized")
        }
    }

    override suspend fun exchangeCodeForToken(code: String) {
        val tokenResponse = requestToken(
            grantType = "authorization_code",
            code = code
        )
        authManager.saveTokens(
            accessToken = tokenResponse.accessToken,
            refreshToken = tokenResponse.refreshToken,
            expiresIn = tokenResponse.expiresIn.toLong()
        )
    }

    override suspend fun clearAuth() {
        authManager.clearAuth()
    }

    private suspend fun refreshToken(refreshToken: String): String {
        val tokenResponse = requestToken(
            grantType = "refresh_token",
            refreshToken = refreshToken
        )
        authManager.saveTokens(
            accessToken = tokenResponse.accessToken,
            refreshToken = tokenResponse.refreshToken,
            expiresIn = tokenResponse.expiresIn.toLong()
        )
        return tokenResponse.accessToken
    }

    private suspend fun requestToken(
        grantType: String,
        code: String? = null,
        refreshToken: String? = null
    ): TokenResponse = withContext(Dispatchers.IO) {
        val url = URL(Constants.TOKEN_URL)
        val connection = url.openConnection() as HttpURLConnection
        
        try {
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

            val postData = buildString {
                append("grant_type=$grantType")
                append("&client_id=${Constants.CLIENT_ID}")
                append("&client_secret=${Constants.CLIENT_SECRET}")
                
                when (grantType) {
                    "authorization_code" -> {
                        append("&code=$code")
                        append("&redirect_uri=${Constants.REDIRECT_URI}")
                    }
                    "refresh_token" -> {
                        append("&refresh_token=$refreshToken")
                    }
                }
            }

            connection.outputStream.use { os ->
                os.write(postData.toByteArray())
            }

            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val jsonResponse = JSONObject(response)

            TokenResponse(
                accessToken = jsonResponse.getString("access_token"),
                refreshToken = jsonResponse.getString("refresh_token"),
                expiresIn = jsonResponse.getInt("expires_in"),
                tokenType = jsonResponse.getString("token_type")
            )
        } finally {
            connection.disconnect()
        }
    }
}
EOL

# Обновляем TokenResponse.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/domain/model/TokenResponse.kt << 'EOL'
package com.example.yandexdiskqr.domain.model

data class TokenResponse(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Int,
    val tokenType: String
)
EOL

# Обновляем build.gradle.kts для security-crypto
cat >> ./app/build.gradle.kts << 'EOL'
dependencies {
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
}
EOL

# Создаем модуль для внедрения зависимостей безопасности
cat > ./app/src/main/java/com/example/yandexdiskqr/di/SecurityModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.security.AuthManager
import com.example.yandexdiskqr.security.EncryptedStorage
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object SecurityModule {

    @Provides
    @Singleton
    fun provideAuthManager(
        encryptedStorage: EncryptedStorage
    ): AuthManager = AuthManager(encryptedStorage)
}
EOL

# Добавляем AuthInterceptor для автоматического обновления токенов
cat > ./app/src/main/java/com/example/yandexdiskqr/security/AuthInterceptor.kt << 'EOL'
package com.example.yandexdiskqr.security

import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class AuthInterceptor @Inject constructor(
    private val authManager: AuthManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        val token = runBlocking {
            when (val state = authManager.checkAuthState().first()) {
                is AuthState.Authorized -> state.token
                is AuthState.NeedsRefresh -> {
                    // Обновляем токен и повторяем запрос
                    authManager.refreshToken(state.refreshToken)
                }
                AuthState.Unauthorized -> null
            }
        }

        val request = originalRequest.newBuilder().apply {
            token?.let { header("Authorization", "OAuth $it") }
        }.build()

        return chain.proceed(request)
    }
}
EOL
