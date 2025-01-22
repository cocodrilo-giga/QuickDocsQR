package com.example.yandexdiskqr.domain.repository

import com.example.yandexdiskqr.data.model.AuthToken

interface AuthRepository {
    suspend fun getAuthToken(): String
    suspend fun exchangeCodeForToken(code: String): Result<Unit>
    suspend fun refreshToken(): AuthToken
    suspend fun clearAuth()
}
