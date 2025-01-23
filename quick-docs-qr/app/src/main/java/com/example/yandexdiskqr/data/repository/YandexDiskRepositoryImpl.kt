package com.example.yandexdiskqr.data.repository

import android.net.Uri
import android.util.Log
import com.example.yandexdiskqr.data.model.DiskException
import com.example.yandexdiskqr.data.model.Resource
import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.squareup.okhttp.MediaType
import com.squareup.okhttp.OkHttpClient
import com.squareup.okhttp.Request
import com.squareup.okhttp.RequestBody
import com.squareup.okhttp.Response
import com.yandex.disk.rest.Credentials
import com.yandex.disk.rest.ResourcesArgs
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.exceptions.ServerIOException
import com.yandex.disk.rest.exceptions.http.UnauthorizedException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
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

    override suspend fun createShareableLink(path: String): Result<String> = withContext(Dispatchers.IO) {
        val token = authRepository.getAuthToken()
        val encodedPath = Uri.encode(path, "/")
        val publishUrl = "https://cloud-api.yandex.net/v1/disk/resources/publish?path=$encodedPath"

        // Создаем пустое тело запроса. В OkHttp v2 используем MediaType из okhttp3
        val mediaType = MediaType.parse("application/json; charset=utf-8")
        val requestBody = RequestBody.create(mediaType, "")

        val publishRequest = Request.Builder()
            .url(publishUrl)
            .put(requestBody) // Используем PUT с пустым телом
            .addHeader("Authorization", "OAuth $token")
            .addHeader("Content-Type", "application/json") // Добавляем заголовок Content-Type
            .build()

        val client = OkHttpClient()
        var publishResponse: com.squareup.okhttp.Response? = null
        var metadataResponse: com.squareup.okhttp.Response? = null

        try {
            // Шаг 1: Публикация ресурса
            publishResponse = client.newCall(publishRequest).execute()
            val publishResponseBody = publishResponse.body()?.string() ?: return@withContext Result.failure(IOException("Empty publish response body"))
            Log.d("YandexDiskRepo", "Publish Response Body: $publishResponseBody")
            val publishJson = JSONObject(publishResponseBody)

            if (!publishResponse.isSuccessful) {
                val message = publishJson.optString("message", "Unknown error")
                val description = publishJson.optString("description", "")
                return@withContext Result.failure(IOException("API Error during publish: $message. $description"))
            }

            // Получаем href для получения метаданных опубликованного ресурса
            val href = publishJson.optString("href", null)
            if (href == null) {
                return@withContext Result.failure(IOException("Missing href in publish response"))
            }

            // Шаг 2: Получение метаданных опубликованного ресурса
            val metadataRequest = Request.Builder()
                .url(href)
                .get()
                .addHeader("Authorization", "OAuth $token")
                .build()

            metadataResponse = client.newCall(metadataRequest).execute()
            val metadataResponseBody = metadataResponse.body()?.string() ?: return@withContext Result.failure(IOException("Empty metadata response body"))
            Log.d("YandexDiskRepo", "Metadata Response Body: $metadataResponseBody")
            val metadataJson = JSONObject(metadataResponseBody)

            if (!metadataResponse.isSuccessful) {
                val message = metadataJson.optString("message", "Unknown error")
                val description = metadataJson.optString("description", "")
                return@withContext Result.failure(IOException("API Error during metadata retrieval: $message. $description"))
            }

            // Извлекаем public_url
            val publicUrl = metadataJson.optString("public_url", null)
            if (publicUrl != null && publicUrl.isNotEmpty()) {
                return@withContext Result.success(publicUrl)
            } else {
                return@withContext Result.failure(IOException("public_url not found in metadata response"))
            }

        } catch (e: Exception) {
            Log.e("YandexDiskRepo", "Exception during createShareableLink: ${e.message}", e)
            return@withContext Result.failure(IOException("Exception: ${e.message}", e))
        } finally {
            publishResponse?.body()?.close()
            metadataResponse?.body()?.close()
        }
    }

    private fun com.yandex.disk.rest.json.Resource.toYandexDiskFile() = YandexDiskFile(
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
