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

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _qrCodeGenerated = MutableLiveData<Bitmap?>()
    val qrCodeGenerated: LiveData<Bitmap?> = _qrCodeGenerated

    fun loadFolders() {
        viewModelScope.launch {
            getFolderContentUseCase("/")
                .onSuccess { folder ->
                    _folders.value = listOf(folder)
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
        }
    }

    fun generateQRCode(folderPath: String) {
        viewModelScope.launch {
            generateQRCodeUseCase(folderPath)
                .onSuccess { bitmap ->
                    _qrCodeGenerated.value = bitmap
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
        }
    }
}
