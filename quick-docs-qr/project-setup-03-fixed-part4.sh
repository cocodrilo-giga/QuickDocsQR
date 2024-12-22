#!/bin/bash

cd YandexDiskQR

# Создание ScannerFragment и ViewModel
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
import com.example.yandexdiskqr.databinding.FragmentScannerBinding
import com.google.android.material.snackbar.Snackbar
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
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
    
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            startCamera()
        } else {
            Snackbar.make(
                binding.root,
                "Camera permission is required",
                Snackbar.LENGTH_INDEFINITE
            ).show()
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
        
        if (hasPermission()) {
            startCamera()
        } else {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }

        observeViewModel()
    }

    private fun hasPermission() = ContextCompat.checkSelfPermission(
        requireContext(),
        Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED

    private fun startCamera() {
        val cameraProviderFuture = ProcessCameraProvider.getInstance(requireContext())
        
        cameraProviderFuture.addListener({
            val cameraProvider = cameraProviderFuture.get()
            
            val preview = Preview.Builder().build()
            preview.setSurfaceProvider(binding.previewView.surfaceProvider)
            
            val imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .apply {
                    setAnalyzer(cameraExecutor) { imageProxy ->
                        processImage(imageProxy)
                    }
                }
            
            try {
                cameraProvider.unbindAll()
                camera = cameraProvider.bindToLifecycle(
                    viewLifecycleOwner,
                    CameraSelector.DEFAULT_BACK_CAMERA,
                    preview,
                    imageAnalyzer
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }, ContextCompat.getMainExecutor(requireContext()))
    }

    private fun processImage(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            val image = InputImage.fromMediaImage(
                mediaImage,
                imageProxy.imageInfo.rotationDegrees
            )
            
            val scanner = BarcodeScanning.getClient()
            scanner.process(image)
                .addOnSuccessListener { barcodes ->
                    barcodes.firstOrNull()?.rawValue?.let { path ->
                        viewModel.onQrCodeScanned(path)
                    }
                }
                .addOnCompleteListener {
                    imageProxy.close()
                }
        } else {
            imageProxy.close()
        }
    }

    private fun observeViewModel() {
        viewModel.navigateToFolder.observe(viewLifecycleOwner) { path ->
            path?.let {
                findNavController().navigate(
                    ScannerFragmentDirections.actionScannerToViewer(path)
                )
                viewModel.onNavigationHandled()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        cameraExecutor.shutdown()
        _binding = null
    }
}
EOL

# Создание ScannerViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/scanner/ScannerViewModel.kt << 'EOL'
package com.example.yandexdiskqr.presentation.scanner

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject

@HiltViewModel
class ScannerViewModel @Inject constructor() : ViewModel() {
    private val _navigateToFolder = MutableLiveData<String?>()
    val navigateToFolder: LiveData<String?> = _navigateToFolder

    fun onQrCodeScanned(path: String) {
        _navigateToFolder.value = path
    }

    fun onNavigationHandled() {
        _navigateToFolder.value = null
    }
}
EOL

# Создание ViewerFragment и ViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/viewer/ViewerFragment.kt << 'EOL'
package com.example.yandexdiskqr.presentation.viewer

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.example.yandexdiskqr.databinding.FragmentViewerBinding
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ViewerFragment : Fragment() {
    private var _binding: FragmentViewerBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: ViewerViewModel by viewModels()
    private val args: ViewerFragmentArgs by navArgs()
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentViewerBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        viewModel.loadFolder(args.folderPath)
        observeViewModel()
    }

    private fun observeViewModel() {
        viewModel.folder.observe(viewLifecycleOwner) { folder ->
            // Update UI with folder contents
        }

        viewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
EOL

# Создание ViewerViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/viewer/ViewerViewModel.kt << 'EOL'
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
EOL

# Создание layout для ViewerFragment
cat > app/src/main/res/layout/fragment_viewer.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:padding="8dp"
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

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

echo "Scanner and Viewer components created successfully!"