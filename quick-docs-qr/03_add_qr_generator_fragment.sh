#!/usr/bin/env bash
set -e

echo "=== 03. Добавляем QRGeneratorFragment.kt ==="

# Создадим нужную папку, если её нет
mkdir -p ./app/src/main/java/com/example/yandexdiskqr/presentation/qr

cat << 'EOF' > ./app/src/main/java/com/example/yandexdiskqr/presentation/qr/QRGeneratorFragment.kt
package com.example.yandexdiskqr.presentation.qr

import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.yandexdiskqr.databinding.FragmentQrGeneratorBinding
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class QRGeneratorFragment : Fragment() {

    private var _binding: FragmentQrGeneratorBinding? = null
    private val binding get() = _binding!!

    private val viewModel: QRGeneratorViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentQrGeneratorBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        observeViewModel()

        binding.generateButton.setOnClickListener {
            val path = binding.folderPathInput.text.toString().trim()
            viewModel.generateQR(path)
        }

        binding.shareQrButton.setOnClickListener {
            val bitmap = viewModel.qrBitmap.value
            if (bitmap != null) {
                shareBitmap(bitmap)
            }
        }
    }

    private fun observeViewModel() {
        viewModel.isLoading.observe(viewLifecycleOwner) { loading ->
            binding.progressBar.visibility = if (loading) View.VISIBLE else View.GONE
        }

        viewModel.qrBitmap.observe(viewLifecycleOwner) { bitmap ->
            if (bitmap != null) {
                binding.qrImage.setImageBitmap(bitmap)
                binding.qrImage.visibility = View.VISIBLE
                binding.shareQrButton.visibility = View.VISIBLE
            } else {
                binding.qrImage.setImageBitmap(null)
                binding.qrImage.visibility = View.GONE
                binding.shareQrButton.visibility = View.GONE
            }
        }

        viewModel.error.observe(viewLifecycleOwner) { errorMessage ->
            errorMessage?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_LONG).show()
            }
        }
    }

    private fun shareBitmap(bitmap: Bitmap) {
        // Упрощённый пример "Поделиться"
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_TEXT, "QR-код для папки")
            // Обычно нужно сохранять bitmap во временный файл и передавать URI через FileProvider
        }
        startActivity(Intent.createChooser(intent, "Share QR code"))
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
EOF

echo "Done. Created QRGeneratorFragment.kt"
