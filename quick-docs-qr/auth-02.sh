#!/bin/bash

# Создаем файл с константами
mkdir -p app/src/main/java/com/example/yandexdiskqr/di
cat > app/src/main/java/com/example/yandexdiskqr/di/Constants.kt << 'EOL'
package com.example.yandexdiskqr.di

object Constants {
    // Эти значения нужно заменить на реальные после регистрации приложения
    // в кабинете разработчика Яндекса: https://oauth.yandex.ru/
    const val CLIENT_ID = "PUT_YOUR_CLIENT_ID_HERE"
    const val CLIENT_SECRET = "PUT_YOUR_CLIENT_SECRET_HERE"
    const val REDIRECT_URI = "ydiskqr://auth"
    
    // Эндпоинты OAuth Яндекса
    const val AUTH_URL = "https://oauth.yandex.ru/authorize"
    const val TOKEN_URL = "https://oauth.yandex.ru/token"
}
EOL

# Создаем модель данных для токена
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/model
cat > app/src/main/java/com/example/yandexdiskqr/data/model/AuthToken.kt << 'EOL'
package com.example.yandexdiskqr.data.model

data class AuthToken(
    val accessToken: String,
    val expiresIn: Long,
    val refreshToken: String,
    val tokenType: String
)
EOL

# Создаем безопасное хранилище для токенов
cat > app/src/main/java/com/example/yandexdiskqr/data/repository/SecureStorageImpl.kt << 'EOL'
package com.example.yandexdiskqr.data.repository

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecureStorageImpl @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePreferences = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveToken(token: String) {
        securePreferences.edit().putString(KEY_ACCESS_TOKEN, token).apply()
    }

    fun getToken(): String? {
        return securePreferences.getString(KEY_ACCESS_TOKEN, null)
    }

    fun saveRefreshToken(token: String) {
        securePreferences.edit().putString(KEY_REFRESH_TOKEN, token).apply()
    }

    fun getRefreshToken(): String? {
        return securePreferences.getString(KEY_REFRESH_TOKEN, null)
    }

    fun clearTokens() {
        securePreferences.edit().clear().apply()
    }

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
    }
}
EOL

# Создаем реализацию AuthRepository
cat > app/src/main/java/com/example/yandexdiskqr/data/repository/AuthRepositoryImpl.kt << 'EOL'
package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.data.model.AuthToken
import com.example.yandexdiskqr.di.Constants
import com.example.yandexdiskqr.domain.repository.AuthRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val secureStorage: SecureStorageImpl
) : AuthRepository {

    override suspend fun getAuthToken(): String {
        return secureStorage.getToken() ?: throw IllegalStateException("No auth token found")
    }

    override suspend fun exchangeCodeForToken(code: String) {
        val token = withContext(Dispatchers.IO) {
            val url = URL(Constants.TOKEN_URL)
            val connection = url.openConnection()
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

            val postData = """
                grant_type=authorization_code
                &code=$code
                &client_id=${Constants.CLIENT_ID}
                &client_secret=${Constants.CLIENT_SECRET}
                &redirect_uri=${Constants.REDIRECT_URI}
            """.trimIndent().replace("\n", "")

            connection.getOutputStream().use { it.write(postData.toByteArray()) }

            val response = connection.getInputStream().bufferedReader().use { it.readText() }
            parseTokenResponse(response)
        }

        secureStorage.saveToken(token.accessToken)
        secureStorage.saveRefreshToken(token.refreshToken)
    }

    override suspend fun refreshToken(): AuthToken {
        return withContext(Dispatchers.IO) {
            val refreshToken = secureStorage.getRefreshToken() 
                ?: throw IllegalStateException("No refresh token found")

            val url = URL(Constants.TOKEN_URL)
            val connection = url.openConnection()
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

            val postData = """
                grant_type=refresh_token
                &refresh_token=$refreshToken
                &client_id=${Constants.CLIENT_ID}
                &client_secret=${Constants.CLIENT_SECRET}
            """.trimIndent().replace("\n", "")

            connection.getOutputStream().use { it.write(postData.toByteArray()) }

            val response = connection.getInputStream().bufferedReader().use { it.readText() }
            val token = parseTokenResponse(response)
            
            secureStorage.saveToken(token.accessToken)
            secureStorage.saveRefreshToken(token.refreshToken)
            
            token
        }
    }

    override suspend fun clearAuth() {
        secureStorage.clearTokens()
    }

    private fun parseTokenResponse(response: String): AuthToken {
        val json = JSONObject(response)
        return AuthToken(
            accessToken = json.getString("access_token"),
            expiresIn = json.getLong("expires_in"),
            refreshToken = json.getString("refresh_token"),
            tokenType = json.getString("token_type")
        )
    }
}
EOL

# Обновляем интерфейс AuthRepository
cat > app/src/main/java/com/example/yandexdiskqr/domain/repository/AuthRepository.kt << 'EOL'
package com.example.yandexdiskqr.domain.repository

import com.example.yandexdiskqr.data.model.AuthToken

interface AuthRepository {
    suspend fun getAuthToken(): String
    suspend fun exchangeCodeForToken(code: String)
    suspend fun refreshToken(): AuthToken
    suspend fun clearAuth()
}
EOL

# Создаем AuthModule
cat > app/src/main/java/com/example/yandexdiskqr/di/AuthModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.AuthRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {
    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository
}
EOL

chmod +x 02_auth.sh
