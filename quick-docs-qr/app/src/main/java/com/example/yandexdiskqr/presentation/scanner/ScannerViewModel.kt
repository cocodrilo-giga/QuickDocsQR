package com.example.yandexdiskqr.presentation.scanner

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor(
    private val repository: YandexDiskRepository
) : ViewModel() {

    private val _navigateToFolder = MutableLiveData<String?>()
    val navigateToFolder: LiveData<String?> = _navigateToFolder

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun onQrCodeScanned(path: String) {
        viewModelScope.launch {
            try {
                // Проверяем существование папки перед навигацией
                repository.getFolderContent(path)
                _navigateToFolder.value = path
            } catch (e: Exception) {
                _error.value = e.message
            }
        }
    }

    fun onNavigationHandled() {
        _navigateToFolder.value = null
    }

    fun onErrorHandled() {
        _error.value = null
    }
}
