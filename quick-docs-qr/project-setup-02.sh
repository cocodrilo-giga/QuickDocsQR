#!/bin/bash

cd YandexDiskQR

# Создание необходимых директорий
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/model
mkdir -p app/src/main/java/com/example/yandexdiskqr/data/repository
mkdir -p app/src/main/java/com/example/yandexdiskqr/domain/repository
mkdir -p app/src/main/java/com/example/yandexdiskqr/domain/usecase

# Создание файлов данных
cat > app/src/main/java/com/example/yandexdiskqr/data/model/YandexDiskFolder.kt << 'EOL'
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
EOL

# Создание репозитория
cat > app/src/main/java/com/example/yandexdiskqr/data/repository/YandexDiskRepositoryImpl.kt << 'EOL'
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
EOL

# Создание доменного слоя
cat > app/src/main/java/com/example/yandexdiskqr/domain/repository/YandexDiskRepository.kt << 'EOL'
package com.example.yandexdiskqr.domain.repository

import com.example.yandexdiskqr.data.model.YandexDiskFolder

interface YandexDiskRepository {
    suspend fun getFolderContent(path: String): YandexDiskFolder
    suspend fun downloadFile(path: String): String
}
EOL

# Создание юзкейсов
cat > app/src/main/java/com/example/yandexdiskqr/domain/usecase/GetFolderContentUseCase.kt << 'EOL'
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.data.model.YandexDiskFolder
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import javax.inject.Inject

class GetFolderContentUseCase @Inject constructor(
    private val repository: YandexDiskRepository
) {
    suspend operator fun invoke(path: String): Result<YandexDiskFolder> = runCatching {
        repository.getFolderContent(path)
    }
}
EOL

cat > app/src/main/java/com/example/yandexdiskqr/domain/usecase/DownloadFileUseCase.kt << 'EOL'
package com.example.yandexdiskqr.domain.usecase

import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import javax.inject.Inject

class DownloadFileUseCase @Inject constructor(
    private val repository: YandexDiskRepository
) {
    suspend operator fun invoke(path: String): Result<String> = runCatching {
        repository.downloadFile(path)
    }
}
EOL

cat > app/src/main/java/com/example/yandexdiskqr/domain/usecase/GenerateQRCodeUseCase.kt << 'EOL'
package com.example.yandexdiskqr.domain.usecase

import android.graphics.Bitmap
import com.google.zxing.BarcodeFormat
import com.google.zxing.qrcode.QRCodeWriter
import javax.inject.Inject

class GenerateQRCodeUseCase @Inject constructor() {
    operator fun invoke(folderPath: String, width: Int = 512, height: Int = 512): Result<Bitmap> = runCatching {
        val writer = QRCodeWriter()
        val bitMatrix = writer.encode(folderPath, BarcodeFormat.QR_CODE, width, height)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565)
        
        for (x in 0 until width) {
            for (y in 0 until height) {
                bitmap.setPixel(x, y, if (bitMatrix[x, y]) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
            }
        }
        
        bitmap
    }
}
EOL

echo "Domain layer and data classes created successfully!"