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
