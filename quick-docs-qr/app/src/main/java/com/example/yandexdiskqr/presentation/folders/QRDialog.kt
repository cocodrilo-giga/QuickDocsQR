package com.example.yandexdiskqr.presentation.folders

import android.app.Dialog
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import androidx.appcompat.app.AlertDialog
import androidx.core.content.FileProvider
import androidx.fragment.app.DialogFragment
import com.example.yandexdiskqr.R
import com.example.yandexdiskqr.databinding.DialogQrCodeBinding
import java.io.File
import java.io.FileOutputStream

class QRDialog : DialogFragment() {
    private var _binding: DialogQrCodeBinding? = null
    private val binding get() = _binding!!

    private lateinit var qrBitmap: Bitmap
    private lateinit var folderPath: String

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        _binding = DialogQrCodeBinding.inflate(LayoutInflater.from(context))

        arguments?.let { bundle ->
            qrBitmap = bundle.getParcelable(ARG_QR_CODE) ?: Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
            folderPath = bundle.getString(ARG_FOLDER_PATH) ?: ""
        }

        binding.qrCodeImage.setImageBitmap(qrBitmap)
        binding.folderPathText.text = folderPath

        binding.shareButton.setOnClickListener {
            shareBitmap(qrBitmap)
        }

        return AlertDialog.Builder(requireContext())
            .setView(binding.root)
            .setTitle(R.string.qr_code_title)
            .setPositiveButton(R.string.close) { _, _ -> dismiss() }
            .create()
    }

    private fun shareBitmap(bitmap: Bitmap) {
        // Сохранение Bitmap во временный файл
        val cachePath = File(requireContext().cacheDir, "images")
        cachePath.mkdirs()
        val file = File(cachePath, "qr_code.png")
        FileOutputStream(file).use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        val fileUri = FileProvider.getUriForFile(requireContext(), "${requireContext().packageName}.provider", file)

        // Создание и запуск Intent для "Поделиться"
        val shareIntent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, fileUri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putExtra(Intent.EXTRA_TEXT, "QR-код для папки $folderPath")
        }
        startActivity(Intent.createChooser(shareIntent, "Поделиться QR-кодом"))
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        private const val ARG_QR_CODE = "qr_code"
        private const val ARG_FOLDER_PATH = "folder_path"

        fun newInstance(qrCode: Bitmap, folderPath: String): QRDialog {
            return QRDialog().apply {
                arguments = Bundle().apply {
                    putParcelable(ARG_QR_CODE, qrCode)
                    putString(ARG_FOLDER_PATH, folderPath)
                }
            }
        }
    }
}
