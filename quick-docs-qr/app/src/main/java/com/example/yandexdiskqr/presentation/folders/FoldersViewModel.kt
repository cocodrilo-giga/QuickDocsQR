package com.example.yandexdiskqr.presentation.folders

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.usecase.GenerateQRCodeUseCase
import com.example.yandexdiskqr.domain.usecase.GetFolderContentUseCase
import com.example.yandexdiskqr.presentation.base.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.graphics.Bitmap

@HiltViewModel
class FoldersViewModel @Inject constructor(
    private val getFolderContentUseCase: GetFolderContentUseCase,
    private val generateQRCodeUseCase: GenerateQRCodeUseCase
) : BaseViewModel() {

    private val _folders = MutableLiveData<List<YandexDiskFolder>>()
    val folders: LiveData<List<YandexDiskFolder>> = _folders

    private val _qrCode = MutableLiveData<Bitmap?>()
    val qrCode: LiveData<Bitmap?> = _qrCode

    private var currentPath = "/"

    fun loadFolders(path: String = "/") {
        viewModelScope.launch {
            try {
                showLoading()
                currentPath = path
                getFolderContentUseCase(path)
                    .onSuccess { folder ->
                        _folders.value = listOf(folder)
                    }
                    .onFailure { error ->
                        handleError(error)
                    }
            } finally {
                hideLoading()
            }
        }
    }

    fun generateQRCode(folderPath: String) {
        viewModelScope.launch {
            try {
                showLoading()
                generateQRCodeUseCase(folderPath)
                    .onSuccess { bitmap ->
                        _qrCode.value = bitmap
                    }
                    .onFailure { error ->
                        handleError(error)
                    }
            } finally {
                hideLoading()
            }
        }
    }

    fun clearQRCode() {
        _qrCode.value = null
    }

    fun navigateUp(): Boolean {
        if (currentPath == "/") return false
        
        val parentPath = currentPath.substringBeforeLast("/", "/")
        loadFolders(parentPath)
        return true
    }
}
