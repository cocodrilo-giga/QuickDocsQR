#!/bin/bash

cd YandexDiskQR

# Создание FoldersFragment и ViewModel
cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersFragment.kt << 'EOL'
package com.example.yandexdiskqr.presentation.folders

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.yandexdiskqr.databinding.FragmentFoldersBinding
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

        viewModel.qrCodeGenerated.observe(viewLifecycleOwner) { bitmap ->
            // Handle QR code generation result
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
EOL

cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersViewModel.kt << 'EOL'
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
EOL

# Создание адаптера для списка папок
cat > app/src/main/java/com/example/yandexdiskqr/presentation/folders/FoldersAdapter.kt << 'EOL'
package com.example.yandexdiskqr.presentation.folders

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.databinding.ItemFolderBinding

class FoldersAdapter(
    private val onFolderClick: (YandexDiskFolder) -> Unit
) : ListAdapter<YandexDiskFolder, FoldersAdapter.FolderViewHolder>(FolderDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FolderViewHolder {
        val binding = ItemFolderBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return FolderViewHolder(binding)
    }

    override fun onBindViewHolder(holder: FolderViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class FolderViewHolder(
        private val binding: ItemFolderBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(folder: YandexDiskFolder) {
            binding.folderName.text = folder.name
            binding.root.setOnClickListener { onFolderClick(folder) }
        }
    }

    private class FolderDiffCallback : DiffUtil.ItemCallback<YandexDiskFolder>() {
        override fun areItemsTheSame(oldItem: YandexDiskFolder, newItem: YandexDiskFolder): Boolean {
            return oldItem.path == newItem.path
        }

        override fun areContentsTheSame(oldItem: YandexDiskFolder, newItem: YandexDiskFolder): Boolean {
            return oldItem == newItem
        }
    }
}
EOL

echo "Fragments and ViewModels created successfully!"