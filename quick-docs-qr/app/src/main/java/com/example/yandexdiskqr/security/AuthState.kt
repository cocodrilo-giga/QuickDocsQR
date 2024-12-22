package com.example.yandexdiskqr.security

sealed class AuthState {
    data class Authorized(val token: String) : AuthState()
    data class NeedsRefresh(val refreshToken: String) : AuthState()
    object Unauthorized : AuthState()
}
