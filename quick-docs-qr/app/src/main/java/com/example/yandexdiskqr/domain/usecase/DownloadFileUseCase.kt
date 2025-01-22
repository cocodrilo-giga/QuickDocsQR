// ./src/main/java/com/example/yandexdiskqr/domain/usecase/DownloadFileUseCase.kt
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import javax.inject.Inject

class DownloadFileUseCase @Inject constructor(
    private val repository: YandexDiskRepository
) {
    suspend operator fun invoke(path: String): Result<String> = repository.downloadFile(path)
}
