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
    private lateinit var shareableLink: String

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        _binding = DialogQrCodeBinding.inflate(LayoutInflater.from(context))

        arguments?.let { bundle ->
            qrBitmap = bundle.getParcelable(ARG_QR_CODE) ?: Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
            shareableLink = bundle.getString(ARG_SHAREABLE_LINK) ?: ""
        }

        binding.qrCodeImage.setImageBitmap(qrBitmap)
        binding.shareLinkText.text = shareableLink

        binding.shareButton.setOnClickListener {
            shareLink(shareableLink)
        }

        return AlertDialog.Builder(requireContext())
            .setView(binding.root)
            .setTitle(R.string.qr_code_title)
            .setPositiveButton(R.string.close) { _, _ -> dismiss() }
            .create()
    }

    private fun shareLink(link: String) {
        val shareIntent = android.content.Intent(android.content.Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(android.content.Intent.EXTRA_TEXT, "Ссылка на папку: $link")
        }
        startActivity(android.content.Intent.createChooser(shareIntent, "Поделиться ссылкой"))
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    companion object {
        private const val ARG_QR_CODE = "qr_code"
        private const val ARG_SHAREABLE_LINK = "shareable_link"

        fun newInstance(qrCode: Bitmap, shareableLink: String): QRDialog {
            return QRDialog().apply {
                arguments = Bundle().apply {
                    putParcelable(ARG_QR_CODE, qrCode)
                    putString(ARG_SHAREABLE_LINK, shareableLink)
                }
            }
        }
    }
}
