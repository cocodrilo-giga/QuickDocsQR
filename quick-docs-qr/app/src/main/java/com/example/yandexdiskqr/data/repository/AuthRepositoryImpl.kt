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
