// ./src/main/java/com/example/yandexdiskqr/data/repository/YandexDiskRepositoryImpl.kt
package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.data.model.DiskException
import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.squareup.okhttp.OkHttpClient
import com.yandex.disk.rest.Credentials
import com.yandex.disk.rest.ResourcesArgs
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.exceptions.ServerIOException
import com.yandex.disk.rest.exceptions.http.UnauthorizedException
import com.yandex.disk.rest.json.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class YandexDiskRepositoryImpl @Inject constructor(
    private val authRepository: AuthRepository
) : YandexDiskRepository {

    override suspend fun getFolderContent(path: String): Result<YandexDiskFolder> =
        withContext(Dispatchers.IO) {
            try {
                val token = authRepository.getAuthToken()
                val user = getUserFromToken(token) // Реализуйте этот метод
                val credentials = Credentials(user, token) // Используем правильный конструктор

                val httpClient = OkHttpClient() // Используем OkHttp2
                val restClient = RestClient(credentials, httpClient) // Передаём оба параметра

                val args = ResourcesArgs.Builder()
                    .setPath(path)
                    .setLimit(100)
                    .build()

                val response = restClient.getResources(args)

                Result.success(YandexDiskFolder(
                    path = response.path.path,
                    name = response.name,
                    files = response.resourceList.items.map { it.toYandexDiskFile() }
                ))
            } catch (e: Exception) {
                Result.failure(handleDiskException(e))
            }
        }

    override suspend fun downloadFile(path: String): Result<String> =
        withContext(Dispatchers.IO) {
            try {
                val token = authRepository.getAuthToken()
                val user = getUserFromToken(token) // Реализуйте этот метод
                val credentials = Credentials(user, token) // Используем правильный конструктор

                val httpClient = OkHttpClient() // Используем OkHttp2
                val restClient = RestClient(credentials, httpClient) // Передаём оба параметра

                val tempFile = File.createTempFile("download", ".tmp")
                restClient.downloadFile(path, tempFile, null)
                Result.success(tempFile.absolutePath)
            } catch (e: Exception) {
                Result.failure(handleDiskException(e))
            }
        }

    private fun Resource.toYandexDiskFile() = YandexDiskFile(
        path = path.path,
        name = name,
        mimeType = mediaType ?: "",
        size = size
    )

    private suspend fun handleDiskException(e: Exception): DiskException {
        return when (e) {
            is UnauthorizedException -> {
                try {
                    authRepository.refreshToken()
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

    /**
     * Пример метода для извлечения пользователя из токена.
     * Реализуйте логику получения пользователя в соответствии с вашим API.
     */
    private suspend fun getUserFromToken(token: String): String {
        // Правильный URL для получения информации о пользователе
        val url = URL("https://login.yandex.ru/info?format=json")
        val connection = withContext(Dispatchers.IO) { url.openConnection() as HttpURLConnection }

        try {
            connection.requestMethod = "GET"
            connection.setRequestProperty("Authorization", "OAuth $token")
            connection.connect()

            val responseCode = connection.responseCode
            if (responseCode != HttpURLConnection.HTTP_OK) {
                throw IOException("Failed to fetch user info: HTTP $responseCode")
            }

            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val jsonResponse = JSONObject(response)
            return jsonResponse.getString("id") // Поле "id" содержит уникальный идентификатор пользователя
        } catch (e: Exception) {
            throw IOException("Error fetching user info: ${e.message}", e)
        } finally {
            connection.disconnect()
        }
    }
}
