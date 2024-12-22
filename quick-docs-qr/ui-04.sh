#!/bin/bash

# Создаем базовый класс для ViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/base/BaseViewModel.kt << 'EOL'
package com.example.yandexdiskqr.presentation.base

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.example.yandexdiskqr.data.model.DiskException
import kotlinx.coroutines.CancellationException

abstract class BaseViewModel : ViewModel() {
    private val _loading = MutableLiveData<Boolean>()
    val loading: LiveData<Boolean> = _loading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    protected fun showLoading() {
        _loading.value = true
    }

    protected fun hideLoading() {
        _loading.value = false
    }

    protected fun handleError(error: Throwable) {
        if (error is CancellationException) return
        
        _error.value = when (error) {
            is DiskException.NetworkError -> "Проверьте подключение к интернету"
            is DiskException.AuthError -> "Необходима повторная авторизация"
            is DiskException.NotFoundError -> "Папка не найдена"
            is DiskException.ServerError -> "Ошибка сервера: ${error.message}"
            else -> "Неизвестная ошибка: ${error.message}"
        }
    }

    protected fun clearError() {
        _error.value = null
    }
}
EOL

# Обновляем FoldersViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersViewModel.kt << 'EOL'
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
EOL

# Создаем QRDialog для показа QR-кода
cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/QRDialog.kt << 'EOL'
package com.example.yandexdiskqr.presentation.folders

import android.app.Dialog
import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import androidx.appcompat.app.AlertDialog
import androidx.fragment.app.DialogFragment
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.DialogQrCodeBinding

class QRDialog : DialogFragment() {
    private var _binding: DialogQrCodeBinding? = null
    private val binding get() = _binding!!

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        _binding = DialogQrCodeBinding.inflate(LayoutInflater.from(context))

        arguments?.getParcelable<Bitmap>(ARG_QR_CODE)?.let { bitmap ->
            binding.qrCodeImage.setImageBitmap(bitmap)
        }

        return AlertDialog.Builder(requireContext())
            .setView(binding.root)
            .setTitle(R.string.qr_code_title)
            .setPositiveButton(R.string.close) { _, _ -> dismiss() }
            .create()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        private const val ARG_QR_CODE = "qr_code"

        fun newInstance(qrCode: Bitmap): QRDialog {
            return QRDialog().apply {
                arguments = Bundle().apply {
                    putParcelable(ARG_QR_CODE, qrCode)
                }
            }
        }
    }
}
EOL

# Создаем layout для QR диалога
mkdir -p app/src/main/res/layout
cat > app/src/main/res/layout/dialog_qr_code.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="16dp">

    <ImageView
        android:id="@+id/qrCodeImage"
        android:layout_width="300dp"
        android:layout_height="300dp"
        android:scaleType="fitCenter"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <TextView
        android:id="@+id/qrCodeHint"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:gravity="center"
        android:text="@string/qr_code_hint"
        android:textAppearance="?attr/textAppearanceBody2"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/qrCodeImage" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Обновляем строковые ресурсы
cat > app/src/main/res/values/strings.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">YandexDisk QR</string>
    <string name="folders">Папки</string>
    <string name="scanner">Сканер</string>
    <string name="viewer">Просмотр</string>
    <string name="generate_qr">Создать QR-код</string>
    <string name="scan_qr">Отсканируйте QR-код для просмотра документов</string>
    <string name="error_loading_folder">Ошибка загрузки папки</string>
    <string name="error_scanning">Ошибка сканирования</string>
    <string name="error_generating_qr">Ошибка создания QR-кода</string>
    <string name="sign_in_with_yandex">Войти через Яндекс</string>
    <string name="auth_error">Ошибка авторизации</string>
    <string name="qr_code_title">QR-код для папки</string>
    <string name="qr_code_hint">Отсканируйте этот QR-код для быстрого доступа к документам</string>
    <string name="close">Закрыть</string>
    <string name="retry">Повторить</string>
    <string name="loading">Загрузка...</string>
    <string name="no_files">В этой папке нет файлов</string>
</resources>
EOL

# Обновляем стили
cat > app/src/main/res/values/styles.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTextAppearance.Error" parent="TextAppearance.MaterialComponents.Body2">
        <item name="android:textColor">@color/error</item>
    </style>

    <style name="AppTextAppearance.Hint" parent="TextAppearance.MaterialComponents.Body2">
        <item name="android:textColor">?android:textColorSecondary</item>
    </style>

    <style name="Widget.App.Button.OutlinedButton.IconOnly" parent="Widget.MaterialComponents.Button.OutlinedButton">
        <item name="iconPadding">0dp</item>
        <item name="android:insetTop">0dp</item>
        <item name="android:insetBottom">0dp</item>
        <item name="android:paddingLeft">12dp</item>
        <item name="android:paddingRight">12dp</item>
        <item name="android:minWidth">48dp</item>
        <item name="android:minHeight">48dp</item>
    </style>
</resources>
EOL

chmod +x 04_ui.sh
