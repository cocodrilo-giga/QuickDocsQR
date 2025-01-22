// ./src/main/java/com/example/yandexdiskqr/presentation/MainViewModel.kt
package com.example.yandexdiskqr.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.domain.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.util.Log

@HiltViewModel
class MainViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    fun exchangeCodeForToken(code: String) {
        viewModelScope.launch {
            val result = authRepository.exchangeCodeForToken(code)
            if (result.isSuccess) {
                Log.d("MainViewModel", "Токен успешно получен")
                // Обновите UI или перейдите к следующему экрану
            } else {
                Log.e("MainViewModel", "Ошибка получения токена: ${result.exceptionOrNull()?.message}")
                // Обработайте ошибку получения токена
            }
        }
    }
}
