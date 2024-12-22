package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
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
    fun provideRestClient(
        authRepository: AuthRepository
    ): RestClient {
        return RestClient(authRepository.getAuthToken())
    }

    @Provides
    @Singleton
    fun provideYandexDiskRepository(
        restClient: RestClient
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(restClient, authRepository)
    }
}
