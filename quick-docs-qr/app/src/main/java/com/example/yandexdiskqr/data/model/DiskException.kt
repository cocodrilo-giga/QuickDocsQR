package com.example.yandexdiskqr.data.model

sealed class DiskException : Exception() {
    data class NetworkError(override val message: String) : DiskException()
    data class AuthError(override val message: String) : DiskException()
    data class NotFoundError(override val message: String) : DiskException()
    data class ServerError(override val message: String) : DiskException()
}
