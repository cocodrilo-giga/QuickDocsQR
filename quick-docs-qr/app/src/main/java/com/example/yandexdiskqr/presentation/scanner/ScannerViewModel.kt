// ./src/main/java/com/example/yandexdiskqr/presentation/scanner/ScannerViewModel.kt
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

    private val _isLoading = MutableLiveData<Boolean>(false)
    val isLoading: LiveData<Boolean> = _isLoading

    fun onQrCodeScanned(path: String) {
        viewModelScope.launch {
            _isLoading.value = true
            repository.getFolderContent(path)
                .onSuccess { folder ->
                    _navigateToFolder.value = folder.path
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
            _isLoading.value = false
        }
    }

    fun onNavigationHandled() {
        _navigateToFolder.value = null
    }

    fun onScanError(message: String) {
        _error.value = message
    }

    fun onErrorHandled() {
        _error.value = null
    }
}
