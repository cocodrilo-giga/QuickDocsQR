package com.example.yandexdiskqr.presentation.common

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.example.yandexdiskqr.util.ErrorHandler
import kotlinx.coroutines.CancellationException

abstract class BaseViewModel(
    private val errorHandler: ErrorHandler
) : ViewModel() {

    protected val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    protected fun handleError(throwable: Throwable) {
        if (throwable !is CancellationException) {
            _error.value = errorHandler.getErrorMessage(throwable)
        }
    }

    fun clearError() {
        _error.value = null
    }
}
