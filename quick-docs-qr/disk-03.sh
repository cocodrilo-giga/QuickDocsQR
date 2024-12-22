#!/bin/bash

# Создаем модели для работы с Яндекс.Диском
cat > app/src/main/java/com/example/yandexdiskqr/data/model/Resource.kt << 'EOL'
package com.example.yandexdiskqr.data.model

sealed class Resource<T> {
    data class Success<T>(val data: T) : Resource<T>()
    data class Error<T>(val message: String) : Resource<T>()
    class Loading<T> : Resource<T>()
}
EOL

cat > app/src/main/java/com/example/yandexdiskqr/data/model/DiskException.kt << 'EOL'
package com.example.yandexdiskqr.data.model

sealed class DiskException : Exception() {
    data class NetworkError(override val message: String) : DiskException()
    data class AuthError(override val message: String) : DiskException()
    data class NotFoundError(override val message: String) : DiskException()
    data class ServerError(override val message: String) : DiskException()
}
EOL

# Обновляем YandexDiskModule с поддержкой динамических токенов
cat > app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.retrofit.RequestInterceptor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object YandexDiskModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(authRepository: AuthRepository): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(Interceptor { chain ->
                val token = runBlocking { authRepository.getAuthToken() }
                val request = chain.request().newBuilder()
                    .addHeader("Authorization", "OAuth $token")
                    .build()
                chain.proceed(request)
            })
            .build()
    }

    @Provides
    @Singleton
    fun provideRestClient(okHttpClient: OkHttpClient): RestClient {
        return RestClient.Builder()
            .setHttpClient(okHttpClient)
            .build()
    }

    @Provides
    @Singleton
    fun provideYandexDiskRepository(
        restClient: RestClient,
        authRepository: AuthRepository
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(restClient, authRepository)
    }
}
EOL

# Обновляем YandexDiskRepositoryImpl с обработкой ошибок
cat > app/src/main/java/com/example/yandexdiskqr/data/repository/YandexDiskRepositoryImpl.kt << 'EOL'
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
EOL

# Обновляем интерфейс репозитория
cat > app/src/main/java/com/example/yandexdiskqr/domain/repository/YandexDiskRepository.kt << 'EOL'
package com.example.yandexdiskqr.domain.repository

import com.example.yandexdiskqr.data.model.YandexDiskFolder

interface YandexDiskRepository {
    suspend fun getFolderContent(path: String): Result<YandexDiskFolder>
    suspend fun downloadFile(path: String): Result<String>
}
EOL

chmod +x 03_disk.sh
