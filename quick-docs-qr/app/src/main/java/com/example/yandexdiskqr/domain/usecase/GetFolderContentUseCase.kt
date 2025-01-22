// ./src/main/java/com/example/yandexdiskqr/domain/usecase/GetFolderContentUseCase.kt
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import javax.inject.Inject

class GetFolderContentUseCase @Inject constructor(
    private val repository: YandexDiskRepository
) {
    suspend operator fun invoke(path: String): Result<YandexDiskFolder> = repository.getFolderContent(path)
}
