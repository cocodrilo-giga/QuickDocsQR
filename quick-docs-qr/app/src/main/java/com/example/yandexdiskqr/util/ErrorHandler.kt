package com.example.yandexdiskqr.util

import android.content.Context
import com.example.yandexdiskqr.R
import com.yandex.disk.rest.exceptions.ServerIOException
import com.yandex.disk.rest.exceptions.UnauthorizedException
import java.net.UnknownHostException
import javax.inject.Inject

class ErrorHandler @Inject constructor(
    private val context: Context
) {
    fun getErrorMessage(throwable: Throwable): String {
        return when (throwable) {
            is UnauthorizedException -> context.getString(R.string.error_unauthorized)
            is ServerIOException -> context.getString(R.string.error_server)
            is UnknownHostException -> context.getString(R.string.error_network)
            else -> throwable.message ?: context.getString(R.string.error_unknown)
        }
    }
}
