package com.example.yandexdiskqr.domain.repository

import com.example.yandexdiskqr.data.model.YandexDiskFolder

interface YandexDiskRepository {
    suspend fun getFolderContent(path: String): Result<YandexDiskFolder>
    suspend fun downloadFile(path: String): Result<String>
}
