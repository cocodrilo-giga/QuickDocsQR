package com.example.yandexdiskqr.presentation.common

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.FrameLayout
import androidx.core.view.isVisible
import com.example.yandexdiskqr.databinding.ViewLoadingButtonBinding

class LoadingButton @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val binding = ViewLoadingButtonBinding.inflate(
        LayoutInflater.from(context),
        this,
        true
    )

    var isLoading: Boolean = false
        set(value) {
            field = value
            binding.progressBar.isVisible = value
            binding.button.isEnabled = !value
        }

    init {
        isLoading = false
    }

    fun setOnClickListener(listener: OnClickListener) {
        binding.button.setOnClickListener(listener)
    }

    fun setText(text: CharSequence) {
        binding.button.text = text
    }
}
