// ./src/main/java/com/example/yandexdiskqr/data/repository/AuthRepositoryImpl.kt
package com.example.yandexdiskqr.data.repository

import android.util.Log
import com.example.yandexdiskqr.data.model.AuthToken
import com.example.yandexdiskqr.di.Constants
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
    private val secureStorage: SecureStorageImpl
) : AuthRepository {

    override suspend fun getAuthToken(): String = withContext(Dispatchers.IO) {
        val token = secureStorage.getToken()
        if (token.isNullOrEmpty()) {
            throw IllegalStateException("Unauthorized: no access token found")
        }
        token
    }

    override suspend fun exchangeCodeForToken(code: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            Log.d("AuthRepositoryImpl", "Отправка запроса на обмен кода на токен")
            val url = URL(Constants.TOKEN_URL)
            val connection = url.openConnection() as HttpURLConnection

            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.setRequestProperty("Content-Type", "application/x-www-form-urlencoded")

            val postData = "grant_type=authorization_code&code=$code&client_id=${Constants.CLIENT_ID}&client_secret=${Constants.CLIENT_SECRET}&redirect_uri=${Constants.REDIRECT_URI}"

            connection.outputStream.use { os ->
                os.write(postData.toByteArray())
            }

            val responseCode = connection.responseCode
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val jsonResponse = JSONObject(response)

                val accessToken = jsonResponse.getString("access_token")
                val refreshToken = jsonResponse.getString("refresh_token")
                val expiresIn = jsonResponse.getLong("expires_in")
                val tokenType = jsonResponse.getString("token_type")

                // Сохраните токены в безопасном хранилище
                secureStorage.saveToken(accessToken)
                secureStorage.saveRefreshToken(refreshToken)

                Log.d("AuthRepositoryImpl", "Токены успешно сохранены")
                Result.success(Unit)
            } else {
                val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() }
                Log.e("AuthRepositoryImpl", "Ошибка обмена кода на токен: $responseCode $errorResponse")
                Result.failure(Exception("Ошибка обмена кода на токен: $responseCode $errorResponse"))
            }
        } catch (e: Exception) {
            Log.e("AuthRepositoryImpl", "Ошибка обмена кода на токен: ${e.message}")
            Result.failure(e)
        }
    }

    override suspend fun refreshToken(): AuthToken {
        val refreshToken = secureStorage.getRefreshToken()
            ?: throw IllegalStateException("Unauthorized: no refresh token found")

        val tokenResponse = requestToken(
            grantType = "refresh_token",
            refreshToken = refreshToken
        )
        secureStorage.saveToken(tokenResponse.accessToken)
        secureStorage.saveRefreshToken(tokenResponse.refreshToken)
        return tokenResponse
    }

    override suspend fun clearAuth() {
        secureStorage.clearTokens()
    }

    /**
     * Запрос токена или его обновление (refresh).
     */
    private suspend fun requestToken(
        grantType: String,
        code: String? = null,
        refreshToken: String? = null
    ): AuthToken = withContext(Dispatchers.IO) {
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

            AuthToken(
                accessToken = jsonResponse.getString("access_token"),
                refreshToken = jsonResponse.getString("refresh_token"),
                expiresIn = jsonResponse.getLong("expires_in"),
                tokenType = jsonResponse.getString("token_type")
            )
        } finally {
            connection.disconnect()
        }
    }
}
