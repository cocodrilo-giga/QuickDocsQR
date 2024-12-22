package com.example.yandexdiskqr.presentation.scanner

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.example.yandexdiskqr.presentation.base.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor() : BaseViewModel() {
    private val _scanResult = MutableLiveData<ScanResult>()
    val scanResult: LiveData<ScanResult> = _scanResult

    fun onQRCodeScanned(path: String) {
        _scanResult.value = ScanResult.Success(path)
    }

    fun onScanError(error: Exception) {
        handleError(error)
        _scanResult.value = ScanResult.Error(error.message ?: "Unknown error")
    }

    fun onNavigationHandled() {
        _scanResult.value = null
    }
}

sealed class ScanResult {
    data class Success(val path: String) : ScanResult()
    data class Error(val message: String) : ScanResult()
}
