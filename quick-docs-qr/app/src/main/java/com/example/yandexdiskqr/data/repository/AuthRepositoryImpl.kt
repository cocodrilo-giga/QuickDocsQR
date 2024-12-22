package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.data.local.AuthDataStore
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
    private val authDataStore: AuthDataStore
) : AuthRepository {

    override suspend fun getAuthToken(): String = withContext(Dispatchers.IO) {
        val token = authDataStore.getAccessToken()
        // При необходимости можно проверить "протух" ли токен (сравнив expiresIn), но пока упрощённо:
        if (token.isNullOrEmpty()) {
            throw IllegalStateException("Unauthorized: no access token found")
        }
        token
    }

    override suspend fun exchangeCodeForToken(code: String) {
        val tokenResponse = requestToken(
            grantType = "authorization_code",
            code = code
        )
        authDataStore.saveTokens(
            accessToken = tokenResponse.accessToken,
            refreshToken = tokenResponse.refreshToken,
            expiresIn = tokenResponse.expiresIn,
            tokenType = tokenResponse.tokenType
        )
    }

    override suspend fun refreshToken(): AuthToken {
        val refreshToken = authDataStore.getRefreshToken()
            ?: throw IllegalStateException("Unauthorized: no refresh token found")

        val tokenResponse = requestToken(
            grantType = "refresh_token",
            refreshToken = refreshToken
        )
        authDataStore.saveTokens(
            accessToken = tokenResponse.accessToken,
            refreshToken = tokenResponse.refreshToken,
            expiresIn = tokenResponse.expiresIn,
            tokenType = tokenResponse.tokenType
        )
        return tokenResponse
    }

    override suspend fun clearAuth() {
        authDataStore.clearTokens()
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
