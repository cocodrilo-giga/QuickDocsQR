package com.example.yandexdiskqr.presentation.folders

import android.graphics.Bitmap
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.domain.usecase.CreateShareableLinkUseCase
import com.example.yandexdiskqr.domain.usecase.GenerateQRCodeUseCase
import com.example.yandexdiskqr.domain.usecase.GetFolderContentUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class FoldersViewModel @Inject constructor(
    private val getFolderContentUseCase: GetFolderContentUseCase,
    private val createShareableLinkUseCase: CreateShareableLinkUseCase,
    private val generateQRCodeUseCase: GenerateQRCodeUseCase
) : ViewModel() {

    private val _folders = MutableLiveData<List<YandexDiskFile>>()
    val folders: LiveData<List<YandexDiskFile>> = _folders

    private val _qrCodeData = MutableLiveData<Pair<Bitmap, String>?>()
    val qrCodeData: LiveData<Pair<Bitmap, String>?> = _qrCodeData

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _isLoading = MutableLiveData<Boolean>(false)
    val isLoading: LiveData<Boolean> = _isLoading

    fun loadFolders() {
        viewModelScope.launch {
            _isLoading.value = true
            getFolderContentUseCase("/")
                .onSuccess { folder ->
                    _folders.value = folder.files // Передаем список файлов (подкаталогов)
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
            _isLoading.value = false
        }
    }

    fun generateQRCode(folderPath: String) {
        if (folderPath.isBlank()) {
            _error.value = "Введите путь к папке!"
            return
        }
        _isLoading.value = true

        viewModelScope.launch {
            // Создание публичной ссылки на папку
            val shareableLinkResult = createShareableLinkUseCase(folderPath)
            shareableLinkResult
                .onSuccess { link ->
                    // Генерация QR-кода на основе ссылки
                    val qrResult = generateQRCodeUseCase(link)
                    qrResult
                        .onSuccess { bitmap ->
                            _qrCodeData.value = bitmap to link
                        }
                        .onFailure { exception ->
                            _error.value = exception.message
                        }
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
            _isLoading.value = false
        }
    }

    fun clearQrCodeData() {
        _qrCodeData.value = null
    }
}
