package com.example.yandexdiskqr.domain.repository

interface AuthRepository {
    suspend fun getAuthToken(): String
    suspend fun exchangeCodeForToken(code: String)
    suspend fun clearAuth()
}
