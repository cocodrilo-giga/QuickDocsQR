#!/bin/bash

# Создаем необходимые директории для диалогов и утилит
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/common
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

# Создаем layout для диалога QR-кода
cat > ./app/src/main/res/layout/dialog_qr_code.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:padding="16dp">

    <ImageView
        android:id="@+id/qrCodeImage"
        android:layout_width="240dp"
        android:layout_height="240dp"
        android:layout_marginTop="16dp"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <TextView
        android:id="@+id/folderPathText"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:gravity="center"
        android:textAppearance="?attr/textAppearanceBody2"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/qrCodeImage" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/shareButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="16dp"
        android:text="@string/share_qr_code"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/folderPathText" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Создаем QrCodeDialog.kt
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/common/QrCodeDialog.kt << 'EOL'
package com.example.yandexdiskqr.presentation.common

import android.app.Dialog
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.provider.MediaStore
import androidx.fragment.app.DialogFragment
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.DialogQrCodeBinding
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import java.io.ByteArrayOutputStream

class QrCodeDialog : DialogFragment() {
    private var _binding: DialogQrCodeBinding? = null
    private val binding get() = _binding!!

    private var qrCodeBitmap: Bitmap? = null
    private var folderPath: String? = null

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        _binding = DialogQrCodeBinding.inflate(layoutInflater)

        qrCodeBitmap?.let { bitmap ->
            binding.qrCodeImage.setImageBitmap(bitmap)
        }

        folderPath?.let { path ->
            binding.folderPathText.text = path
        }

        binding.shareButton.setOnClickListener {
            shareQrCode()
        }

        return MaterialAlertDialogBuilder(requireContext())
            .setView(binding.root)
            .setTitle(R.string.qr_code_title)
            .setPositiveButton(R.string.close, null)
            .create()
    }

    private fun shareQrCode() {
        qrCodeBitmap?.let { bitmap ->
            val bytes = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, bytes)
            
            val path = MediaStore.Images.Media.insertImage(
                requireContext().contentResolver,
                bitmap,
                "QR Code",
                folderPath
            )

            path?.let {
                val uri = android.net.Uri.parse(path)
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "image/png"
                    putExtra(Intent.EXTRA_STREAM, uri)
                }
                startActivity(Intent.createChooser(intent, getString(R.string.share_qr_code)))
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        fun newInstance(qrCode: Bitmap, path: String) = QrCodeDialog().apply {
            this.qrCodeBitmap = qrCode
            this.folderPath = path
        }
    }
}
EOL

# Обновляем строковые ресурсы
cat >> ./app/src/main/res/values/strings.xml << 'EOL'
    <string name="qr_code_title">QR-код для папки</string>
    <string name="share_qr_code">Поделиться QR-кодом</string>
    <string name="close">Закрыть</string>
    <string name="camera_permission_required">Для сканирования QR-кода необходимо разрешение на использование камеры</string>
    <string name="error_invalid_qr">Некорректный QR-код</string>
    <string name="error_folder_not_found">Папка не найдена</string>
EOL

# Обновляем FoldersViewModel.kt для работы с QR-диалогом
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersViewModel.kt << 'EOL'
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
EOL

# Обновляем FoldersFragment.kt для показа QR-диалога
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersFragment.kt << 'EOL'
package com.example.yandexdiskqr.presentation.folders

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.isVisible
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.FragmentFoldersBinding
import com.example.yandexdiskqr.presentation.common.QrCodeDialog
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class FoldersFragment : Fragment() {
    private var _binding: FragmentFoldersBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: FoldersViewModel by viewModels()
    private val foldersAdapter = FoldersAdapter { folder ->
        viewModel.generateQRCode(folder.path)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentFoldersBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        observeViewModel()
        
        viewModel.loadFolders()
    }

    private fun setupRecyclerView() {
        binding.recyclerView.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = foldersAdapter
        }
    }

    private fun observeViewModel() {
        viewModel.folders.observe(viewLifecycleOwner) { folders ->
            foldersAdapter.submitList(folders)
        }

        viewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_LONG).show()
            }
        }

        viewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            binding.progressBar.isVisible = isLoading
        }

        viewModel.qrCodeData.observe(viewLifecycleOwner) { qrData ->
            qrData?.let { (bitmap, path) ->
                QrCodeDialog.newInstance(bitmap, path)
                    .show(childFragmentManager, "qr_code_dialog")
                viewModel.clearQrCodeData()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
EOL

# Обновляем сканер для лучшей обработки ошибок
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/scanner/ScannerViewModel.kt << 'EOL'
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
EOL
