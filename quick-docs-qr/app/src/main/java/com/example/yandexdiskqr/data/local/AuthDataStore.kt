package com.example.yandexdiskqr.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.first

private val Context.authDataStore: DataStore<Preferences> by preferencesDataStore(name = "auth_prefs")

class AuthDataStore(context: Context) {

    private val dataStore = context.authDataStore

    companion object {
        val ACCESS_TOKEN = stringPreferencesKey("access_token")
        val REFRESH_TOKEN = stringPreferencesKey("refresh_token")
        val EXPIRES_IN = longPreferencesKey("expires_in")
        val TOKEN_TYPE = stringPreferencesKey("token_type")
    }

    suspend fun getAccessToken(): String? {
        val prefs = dataStore.data.first()
        return prefs[ACCESS_TOKEN]
    }

    suspend fun getRefreshToken(): String? {
        val prefs = dataStore.data.first()
        return prefs[REFRESH_TOKEN]
    }

    suspend fun getExpiresIn(): Long {
        val prefs = dataStore.data.first()
        return prefs[EXPIRES_IN] ?: 0
    }

    suspend fun getTokenType(): String? {
        val prefs = dataStore.data.first()
        return prefs[TOKEN_TYPE]
    }

    suspend fun saveTokens(
        accessToken: String,
        refreshToken: String,
        expiresIn: Long,
        tokenType: String
    ) {
        dataStore.edit { prefs ->
            prefs[ACCESS_TOKEN] = accessToken
            prefs[REFRESH_TOKEN] = refreshToken
            prefs[EXPIRES_IN] = expiresIn
            prefs[TOKEN_TYPE] = tokenType
        }
    }

    suspend fun clearTokens() {
        dataStore.edit { it.clear() }
    }
}
