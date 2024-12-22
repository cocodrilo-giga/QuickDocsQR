#!/usr/bin/env bash
set -e

echo "=== 02. Добавляем QRGeneratorViewModel.kt ==="

# Создадим нужную папку, если её нет
mkdir -p ./app/src/main/java/com/example/yandexdiskqr/presentation/qr

cat << 'EOF' > ./app/src/main/java/com/example/yandexdiskqr/presentation/qr/QRGeneratorViewModel.kt
package com.example.yandexdiskqr.presentation.qr

import android.graphics.Bitmap
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.domain.usecase.GenerateQRCodeUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class QRGeneratorViewModel @Inject constructor(
    private val generateQRCodeUseCase: GenerateQRCodeUseCase
) : ViewModel() {

    private val _qrBitmap = MutableLiveData<Bitmap?>()
    val qrBitmap: LiveData<Bitmap?> = _qrBitmap

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _isLoading = MutableLiveData<Boolean>(false)
    val isLoading: LiveData<Boolean> = _isLoading

    fun generateQR(folderPath: String) {
        if (folderPath.isBlank()) {
            _error.value = "Введите путь к папке!"
            return
        }
        _isLoading.value = true

        viewModelScope.launch {
            val result = generateQRCodeUseCase(folderPath)
            _isLoading.value = false

            result
                .onSuccess { bitmap ->
                    _qrBitmap.value = bitmap
                }
                .onFailure { exception ->
                    _error.value = exception.message
                }
        }
    }
}
EOF

echo "Done. Created QRGeneratorViewModel.kt"
