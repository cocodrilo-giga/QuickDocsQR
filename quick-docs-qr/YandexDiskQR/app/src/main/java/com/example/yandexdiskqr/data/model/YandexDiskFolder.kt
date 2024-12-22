package com.example.yandexdiskqr.data.model

data class YandexDiskFolder(
    val path: String,
    val name: String,
    val files: List<YandexDiskFile> = emptyList()
)

data class YandexDiskFile(
    val path: String,
    val name: String,
    val mimeType: String,
    val size: Long
)
