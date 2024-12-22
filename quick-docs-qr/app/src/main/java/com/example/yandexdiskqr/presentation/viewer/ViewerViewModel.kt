package com.example.yandexdiskqr.presentation.viewer

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.usecase.GetFolderContentUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class ViewerViewModel @Inject constructor(
    private val getFolderContentUseCase: GetFolderContentUseCase
) : ViewModel() {

    private val _folder = MutableLiveData<YandexDiskFolder>()
    val folder: LiveData<YandexDiskFolder> = _folder

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun loadFolder(path: String) {
        viewModelScope.launch {
            getFolderContentUseCase(path)
                .onSuccess { folder ->
                    _folder.value = folder
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
        }
    }
}
