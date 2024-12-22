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

    override fun onCreateDialog(savedInstanceState: Bundle?): Dialog {
        _binding = DialogQrCodeBinding.inflate(LayoutInflater.from(context))

        arguments?.getParcelable<Bitmap>(ARG_QR_CODE)?.let { bitmap ->
            binding.qrCodeImage.setImageBitmap(bitmap)
        }

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

        fun newInstance(qrCode: Bitmap): QRDialog {
            return QRDialog().apply {
                arguments = Bundle().apply {
                    putParcelable(ARG_QR_CODE, qrCode)
                }
            }
        }
    }
}
