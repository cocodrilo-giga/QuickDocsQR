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
