package com.example.yandexdiskqr.presentation.auth

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.yandexdiskqr.domain.usecase.GetAuthTokenUseCase
import com.example.yandexdiskqr.domain.usecase.SaveAuthTokenUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val getAuthTokenUseCase: GetAuthTokenUseCase,
    private val saveAuthTokenUseCase: SaveAuthTokenUseCase
) : ViewModel() {

    private val _authState = MutableLiveData<AuthState>()
    val authState: LiveData<AuthState> = _authState

    fun checkAuth() {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            getAuthTokenUseCase()
                .onSuccess { token ->
                    if (token.isNotEmpty()) {
                        _authState.value = AuthState.Authenticated
                    } else {
                        _authState.value = AuthState.Unauthenticated
                    }
                }
                .onFailure {
                    _authState.value = AuthState.Unauthenticated
                }
        }
    }

    fun exchangeCodeForToken(code: String) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            saveAuthTokenUseCase(code)
                .onSuccess {
                    _authState.value = AuthState.Authenticated
                }
                .onFailure { exception ->
                    _authState.value = AuthState.Error(exception.message ?: "Authentication failed")
                }
        }
    }
}
