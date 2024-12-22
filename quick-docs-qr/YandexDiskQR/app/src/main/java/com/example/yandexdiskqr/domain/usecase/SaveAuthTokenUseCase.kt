package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.AuthRepository
import javax.inject.Inject

class SaveAuthTokenUseCase @Inject constructor(
    private val authRepository: AuthRepository
) {
    suspend operator fun invoke(code: String): Result<Unit> = runCatching {
        authRepository.exchangeCodeForToken(code)
    }
}
