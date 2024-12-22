package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.AuthRepository
import javax.inject.Inject

class GetAuthTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(): Result<String> = runCatching {
        authRepository.getAuthToken()
    }
}
