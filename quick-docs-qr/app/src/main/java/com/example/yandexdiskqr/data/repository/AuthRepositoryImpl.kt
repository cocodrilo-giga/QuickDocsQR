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
