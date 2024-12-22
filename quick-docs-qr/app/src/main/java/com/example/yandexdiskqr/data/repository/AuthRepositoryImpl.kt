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
