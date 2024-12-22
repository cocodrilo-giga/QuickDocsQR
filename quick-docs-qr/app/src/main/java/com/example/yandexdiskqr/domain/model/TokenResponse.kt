package com.example.yandexdiskqr.domain.model

data class TokenResponse(
    val accessToken: String,
    val expiresIn: Int,
    val tokenType: String
)
