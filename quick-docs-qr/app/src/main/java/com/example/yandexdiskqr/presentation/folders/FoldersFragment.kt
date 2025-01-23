package com.example.yandexdiskqr.presentation.folders

import android.graphics.Bitmap
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

        viewModel.qrCodeData.observe(viewLifecycleOwner) { qrData ->
            qrData?.let { (bitmap, path) ->
                showQRCodeDialog(bitmap, path)
                viewModel.clearQrCodeData()
            }
        }
    }

    private fun showQRCodeDialog(bitmap: Bitmap, path: String) {
        // Создайте диалог для отображения QR-кода
        QRDialog.newInstance(bitmap, path).show(parentFragmentManager, "QRDialog")
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
