#!/bin/bash

# Создаем необходимые директории
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/local
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/repository
mkdir -p app/src/main/java/com/example/yandexdiskqr/di
mkdir -p app/src/main/java/com/example/yandexdiskqr/domain/model

# Создаем AuthDataStore.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/data/local/AuthDataStore.kt << 'EOL'
package com.example.yandexdiskqr.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "auth")

@Singleton
class AuthDataStore @Inject constructor(
    private val context: Context
) {
    private val tokenKey = stringPreferencesKey("oauth_token")

    suspend fun saveToken(token: String) {
        context.dataStore.edit { preferences ->
            preferences[tokenKey] = token
        }
    }

    suspend fun getToken(): String {
        return context.dataStore.data.map { preferences ->
            preferences[tokenKey] ?: ""
        }.first()
    }

    suspend fun clearToken() {
        context.dataStore.edit { preferences ->
            preferences.remove(tokenKey)
        }
    }
}
EOL

# Создаем AuthRepository.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/data/repository/AuthRepositoryImpl.kt << 'EOL'
package com.example.yandexdiskqr.data.repository

import android.net.Uri
import com.example.yandexdiskqr.data.local.AuthDataStore
import com.example.yandexdiskqr.di.Constants
import com.example.yandexdiskqr.domain.model.TokenResponse
import com.example.yandexdiskqr.domain.repository.AuthRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepositoryImpl @Inject constructor(
    private val authDataStore: AuthDataStore
) : AuthRepository {

    override suspend fun getAuthToken(): String = authDataStore.getToken()

    override suspend fun exchangeCodeForToken(code: String) {
        val tokenResponse = requestToken(code)
        authDataStore.saveToken(tokenResponse.accessToken)
    }

    override suspend fun clearAuth() {
        authDataStore.clearToken()
    }

    private suspend fun requestToken(code: String): TokenResponse = withContext(Dispatchers.IO) {
        val url = URL(Constants.TOKEN_URL)
        val connection = url.openConnection() as HttpURLConnection
        
        try {
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

            val postData = Uri.Builder()
                .appendQueryParameter("grant_type", "authorization_code")
                .appendQueryParameter("code", code)
                .appendQueryParameter("client_id", Constants.CLIENT_ID)
                .appendQueryParameter("client_secret", Constants.CLIENT_SECRET)
                .build()
                .query

            connection.outputStream.use { os ->
                os.write(postData?.toByteArray() ?: byteArrayOf())
            }

            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val jsonResponse = JSONObject(response)

            TokenResponse(
                accessToken = jsonResponse.getString("access_token"),
                expiresIn = jsonResponse.getInt("expires_in"),
                tokenType = jsonResponse.getString("token_type")
            )
        } finally {
            connection.disconnect()
        }
    }
}
EOL

# Создаем TokenResponse.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/domain/model/TokenResponse.kt << 'EOL'
package com.example.yandexdiskqr.domain.model

data class TokenResponse(
    val accessToken: String,
    val expiresIn: Int,
    val tokenType: String
)
EOL

# Обновляем Constants.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/di/Constants.kt << 'EOL'
package com.example.yandexdiskqr.di

object Constants {
    const val CLIENT_ID = "your_client_id_here"
    const val CLIENT_SECRET = "your_client_secret_here"
    const val REDIRECT_URI = "ydiskqr://auth"
    const val OAUTH_URL = "https://oauth.yandex.ru/authorize"
    const val TOKEN_URL = "https://oauth.yandex.ru/token"
}
EOL

# Создаем AuthModule.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/di/AuthModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import android.content.Context
import com.example.yandexdiskqr.data.local.AuthDataStore
import com.example.yandexdiskqr.data.repository.AuthRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AuthModule {

    @Provides
    @Singleton
    fun provideAuthDataStore(
        @ApplicationContext context: Context
    ): AuthDataStore = AuthDataStore(context)

    @Provides
    @Singleton
    fun provideAuthRepository(
        authDataStore: AuthDataStore
    ): AuthRepository = AuthRepositoryImpl(authDataStore)
}
EOL

# Обновляем YandexDiskModule.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object YandexDiskModule {

    @Provides
    @Singleton
    fun provideRestClient(
        authRepository: AuthRepository
    ): RestClient {
        return RestClient(authRepository.getAuthToken())
    }

    @Provides
    @Singleton
    fun provideYandexDiskRepository(
        restClient: RestClient
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(restClient)
    }
}
EOL
