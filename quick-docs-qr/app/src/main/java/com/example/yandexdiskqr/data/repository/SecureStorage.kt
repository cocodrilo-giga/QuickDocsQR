// ./src/main/java/com/example/yandexdiskqr/domain/repository/SecureStorage.kt
package com.example.yandexdiskqr.domain.repository

interface SecureStorage {
    fun saveToken(token: String)
    fun getToken(): String?
    fun saveRefreshToken(refreshToken: String)
    fun getRefreshToken(): String?
    fun clearTokens()
}
