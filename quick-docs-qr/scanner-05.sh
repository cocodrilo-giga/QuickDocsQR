#!/bin/bash

# Создаем класс для анализа QR-кодов
cat > app/src/main/java/com/example/yandexdiskqr/presentation/scanner/QRCodeAnalyzer.kt << 'EOL'
package com.example.yandexdiskqr.presentation.scanner

import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import java.util.concurrent.Executors

class QRCodeAnalyzer(
    private val onQRCodeDetected: (String) -> Unit,
    private val onError: (Exception) -> Unit
) : ImageAnalysis.Analyzer {
    private val executor = Executors.newSingleThreadExecutor()
    private val options = BarcodeScannerOptions.Builder()
        .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
        .build()
    private val scanner = BarcodeScanning.getClient(options)

    @ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(
                mediaImage,
                imageProxy.imageInfo.rotationDegrees
            )

            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    barcodes.firstOrNull()?.rawValue?.let { qrContent ->
                        // Проверяем, что QR-код содержит валидный путь к папке
                        if (isValidYandexDiskPath(qrContent)) {
                            onQRCodeDetected(qrContent)
                        }
                    }
                }
                .addOnFailureListener { e ->
                    onError(e)
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }

    private fun isValidYandexDiskPath(path: String): Boolean {
        // Путь должен начинаться с "/" и не содержать спецсимволов
        return path.startsWith("/") && 
               path.matches(Regex("^/[\\w\\-./]+$"))
    }
}
EOL

# Обновляем ScannerViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/scanner/ScannerViewModel.kt << 'EOL'
package com.example.yandexdiskqr.presentation.scanner

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.example.yandexdiskqr.presentation.base.BaseViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor() : BaseViewModel() {
    private val _scanResult = MutableLiveData<ScanResult>()
    val scanResult: LiveData<ScanResult> = _scanResult

    fun onQRCodeScanned(path: String) {
        _scanResult.value = ScanResult.Success(path)
    }

    fun onScanError(error: Exception) {
        handleError(error)
        _scanResult.value = ScanResult.Error(error.message ?: "Unknown error")
    }

    fun onNavigationHandled() {
        _scanResult.value = null
    }
}

sealed class ScanResult {
    data class Success(val path: String) : ScanResult()
    data class Error(val message: String) : ScanResult()
}
EOL

# Обновляем ScannerFragment
cat > app/src/main/java/com/example/yandexdiskqr/presentation/scanner/ScannerFragment.kt << 'EOL'
package com.example.yandexdiskqr.presentation.scanner

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.FragmentScannerBinding
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

@AndroidEntryPoint
class ScannerFragment : Fragment() {
    private var _binding: FragmentScannerBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: ScannerViewModel by viewModels()
    private lateinit var cameraExecutor: ExecutorService
    private var camera: Camera? = null
    private var isScanning = true
    
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startCamera()
        } else {
            showPermissionError()
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentScannerBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        cameraExecutor = Executors.newSingleThreadExecutor()

        setupCamera()
        observeViewModel()
        setupViews()
    }

    private fun setupViews() {
        binding.toggleFlashButton.setOnClickListener {
            toggleFlash()
        }
    }

    private fun setupCamera() {
        if (hasPermission()) {
            startCamera()
        } else {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    private fun hasPermission() = ContextCompat.checkSelfPermission(
        requireContext(),
        Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(requireContext())
        
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            
            val preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(binding.previewView.surfaceProvider)
                }
            
            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .apply {
                    setAnalyzer(cameraExecutor, QRCodeAnalyzer(
                        onQRCodeDetected = { path -> 
                            if (isScanning) {
                                isScanning = false
                                viewModel.onQRCodeScanned(path)
                            }
                        },
                        onError = { error ->
                            viewModel.onScanError(error)
                        }
                    ))
                }
            
            try {
                cameraProvider.unbindAll()
                camera = cameraProvider.bindToLifecycle(
                    viewLifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    imageAnalyzer
                )
                
                // Проверяем поддержку вспышки
                binding.toggleFlashButton.visibility = 
                    if (camera?.cameraInfo?.hasFlashUnit() == true) View.VISIBLE
                    else View.GONE
                
            } catch (e: Exception) {
                viewModel.onScanError(e)
            }
        }, ContextCompat.getMainExecutor(requireContext()))
    }

    private fun toggleFlash() {
        camera?.cameraControl?.enableTorch(
            camera?.cameraInfo?.torchState?.value != TorchState.ON
        )
    }

    private fun observeViewModel() {
        viewModel.scanResult.observe(viewLifecycleOwner) { result ->
            when (result) {
                is ScanResult.Success -> {
                    findNavController().navigate(
                        ScannerFragmentDirections.actionScannerToViewer(result.path)
                    )
                    viewModel.onNavigationHandled()
                    isScanning = true
                }
                is ScanResult.Error -> {
                    showError(result.message)
                    isScanning = true
                }
                null -> {
                    isScanning = true
                }
            }
        }

        viewModel.loading.observe(viewLifecycleOwner) { isLoading ->
            binding.scannerOverlay.visibility = if (isLoading) View.INVISIBLE else View.VISIBLE
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }

        viewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let { showError(it) }
        }
    }

    private fun showError(message: String) {
        Snackbar.make(binding.root, message, Snackbar.LENGTH_LONG)
            .setAction(R.string.retry) {
                isScanning = true
            }
            .show()
    }

    private fun showPermissionError() {
        Snackbar.make(
            binding.root,
            R.string.camera_permission_required,
            Snackbar.LENGTH_INDEFINITE
        ).setAction(R.string.grant_permission) {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }.show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        cameraExecutor.shutdown()
        _binding = null
    }
}
EOL

# Обновляем layout сканера
cat > app/src/main/res/layout/fragment_scanner.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.camera.view.PreviewView
        android:id="@+id/previewView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <View
        android:id="@+id/scannerOverlay"
        android:layout_width="250dp"
        android:layout_height="250dp"
        android:background="@drawable/scanner_overlay"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <com.google.android.material.progressindicator.CircularProgressIndicator
        android:id="@+id/progressBar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <TextView
        android:id="@+id/scannerHint"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="32dp"
        android:padding="16dp"
        android:background="@drawable/scanner_hint_background"
        android:text="@string/scan_qr"
        android:textAppearance="?attr/textAppearanceBody1"
        android:textColor="@color/white"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/scannerOverlay" />

    <com.google.android.material.floatingactionbutton.FloatingActionButton
        android:id="@+id/toggleFlashButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_margin="16dp"
        android:src="@drawable/ic_flash_on"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Добавляем фоны и иконки
cat > app/src/main/res/drawable/scanner_hint_background.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#99000000" />
    <corners android:radius="8dp" />
</shape>
EOL

cat > app/src/main/res/drawable/ic_flash_on.xml << 'EOL'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M7,2v11h3v9l7,-12h-4l4,-8z"/>
</vector>
EOL

# Добавляем строки
cat >> app/src/main/res/values/strings.xml << 'EOL'
    <string name="camera_permission_required">Для сканирования QR-кодов необходим доступ к камере</string>
    <string name="grant_permission">Предоставить доступ</string>
    <string name="flash_on">Включить вспышку</string>
    <string name="flash_off">Выключить вспышку</string>
EOL

chmod +x 05_scanner.sh
