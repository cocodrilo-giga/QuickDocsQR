package com.example.yandexdiskqr.presentation.scanner

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor() : ViewModel() {
    private val _navigateToFolder = MutableLiveData<String?>()
    val navigateToFolder: LiveData<String?> = _navigateToFolder

    fun onQrCodeScanned(path: String) {
        _navigateToFolder.value = path
    }

    fun onNavigationHandled() {
        _navigateToFolder.value = null
    }
}
