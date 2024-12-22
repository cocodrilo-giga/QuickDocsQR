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
