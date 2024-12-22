#!/bin/bash

cd YandexDiskQR

# Создание директории для DI модулей
mkdir -p app/src/main/java/com/example/yandexdiskqr/di

# Создание модуля для YandexDisk
cat > app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt << 'EOL'
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object YandexDiskModule {

    @Provides
    @Singleton
    fun provideRestClient(): RestClient {
        // В реальном приложении токен должен быть получен после OAuth авторизации
        return RestClient("YOUR_OAUTH_TOKEN")
    }

    @Provides
    @Singleton
    fun provideYandexDiskRepository(
        restClient: RestClient
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(restClient)
    }
}
EOL

# Создание констант
cat > app/src/main/java/com/example/yandexdiskqr/di/Constants.kt << 'EOL'
package com.example.yandexdiskqr.di

object Constants {
    const val CLIENT_ID = "your_client_id"
    const val REDIRECT_URI = "ydiskqr://auth"
}
EOL

echo "DI components created successfully!"