// ./src/main/java/com/example/yandexdiskqr/presentation/folders/QRDialog.kt
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
