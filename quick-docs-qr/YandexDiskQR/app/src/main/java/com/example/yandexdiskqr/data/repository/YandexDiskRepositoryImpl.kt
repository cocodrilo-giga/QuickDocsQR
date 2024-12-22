package com.example.yandexdiskqr.data.repository

import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.json.Resource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class YandexDiskRepositoryImpl @Inject constructor(
    private val restClient: RestClient
) : YandexDiskRepository {

    override suspend fun getFolderContent(path: String): YandexDiskFolder = withContext(Dispatchers.IO) {
        val response = restClient.getResources(path, 0)
        val resource = response.resourceList
        
        YandexDiskFolder(
            path = resource.path.path,
            name = resource.name,
            files = resource.items.map { it.toYandexDiskFile() }
        )
    }

    override suspend fun downloadFile(path: String): String = withContext(Dispatchers.IO) {
        val tempFile = createTempFile()
        restClient.downloadFile(path, tempFile)
        tempFile.absolutePath
    }

    private fun Resource.toYandexDiskFile() = YandexDiskFile(
        path = path.path,
        name = name,
        mimeType = mimeType,
        size = size
    )
}
