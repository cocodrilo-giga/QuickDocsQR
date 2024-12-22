package com.example.yandexdiskqr.security

import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class AuthInterceptor @Inject constructor(
    private val authManager: AuthManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        
        val token = runBlocking {
            when (val state = authManager.checkAuthState().first()) {
                is AuthState.Authorized -> state.token
                is AuthState.NeedsRefresh -> {
                    // Обновляем токен и повторяем запрос
                    authManager.refreshToken(state.refreshToken)
                }
                AuthState.Unauthorized -> null
            }
        }

        val request = originalRequest.newBuilder().apply {
            token?.let { header("Authorization", "OAuth $it") }
        }.build()

        return chain.proceed(request)
    }
}
