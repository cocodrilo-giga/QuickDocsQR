package com.example.yandexdiskqr.presentation.folders

import android.graphics.Bitmap
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.usecase.GenerateQRCodeUseCase
import com.example.yandexdiskqr.domain.usecase.GetFolderContentUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FoldersViewModel @Inject constructor(
    private val getFolderContentUseCase: GetFolderContentUseCase,
    private val generateQRCodeUseCase: GenerateQRCodeUseCase
) : ViewModel() {

    private val _folders = MutableLiveData<List<YandexDiskFolder>>()
    val folders: LiveData<List<YandexDiskFolder>> = _folders

    private val _qrCodeData = MutableLiveData<Pair<Bitmap, String>?>()
    val qrCodeData: LiveData<Pair<Bitmap, String>?> = _qrCodeData

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading

    fun loadFolders() {
        viewModelScope.launch {
            _isLoading.value = true
            getFolderContentUseCase("/")
                .onSuccess { folder ->
                    _folders.value = listOf(folder)
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
            _isLoading.value = false
        }
    }

    fun generateQRCode(folderPath: String) {
        viewModelScope.launch {
            generateQRCodeUseCase(folderPath)
                .onSuccess { bitmap ->
                    _qrCodeData.value = bitmap to folderPath
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
        }
    }

    fun clearQrCodeData() {
        _qrCodeData.value = null
    }
}
