package com.example.yandexdiskqr.data.model

data class AuthToken(
    val accessToken: String,
    val expiresIn: Long,
    val refreshToken: String,
    val tokenType: String
)
