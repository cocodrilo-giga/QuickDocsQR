package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.data.model.DiskException
import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.exceptions.ServerIOException
import com.yandex.disk.rest.exceptions.UnauthorizedException
import com.yandex.disk.rest.json.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class YandexDiskRepositoryImpl @Inject constructor(
    private val restClient: RestClient,
    private val authRepository: AuthRepository
) : YandexDiskRepository {

    override suspend fun getFolderContent(path: String): Result<YandexDiskFolder> = 
        withContext(Dispatchers.IO) {
            try {
                val response = restClient.getResources(path, 100)  // Увеличиваем лимит
                val resource = response.resourceList

                Result.success(YandexDiskFolder(
                    path = resource.path.path,
                    name = resource.name,
                    files = resource.items.map { it.toYandexDiskFile() }
                ))
            } catch (e: Exception) {
                Result.failure(handleDiskException(e))
            }
        }

    override suspend fun downloadFile(path: String): Result<String> = 
        withContext(Dispatchers.IO) {
            try {
                val tempFile = createTempFile()
                restClient.downloadFile(path, tempFile, null, null)
                Result.success(tempFile.absolutePath)
            } catch (e: Exception) {
                Result.failure(handleDiskException(e))
            }
        }

    private fun Resource.toYandexDiskFile() = YandexDiskFile(
        path = path.path,
        name = name,
        mimeType = mimeType ?: "",
        size = size
    )

    private suspend fun handleDiskException(e: Exception): DiskException {
        return when (e) {
            is UnauthorizedException -> {
                try {
                    // Пробуем обновить токен
                    authRepository.refreshToken()
                    // Если обновление успешно, возвращаем ошибку для повторной попытки
                    DiskException.AuthError("Token refreshed, please retry")
                } catch (refreshError: Exception) {
                    DiskException.AuthError("Authentication failed: ${refreshError.message}")
                }
            }
            is ServerIOException -> DiskException.ServerError("Server error: ${e.message}")
            is IOException -> DiskException.NetworkError("Network error: ${e.message}")
            else -> DiskException.ServerError("Unknown error: ${e.message}")
        }
    }
}
