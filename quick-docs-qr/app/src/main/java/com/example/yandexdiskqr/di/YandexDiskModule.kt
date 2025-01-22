// ./src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt
package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.example.yandexdiskqr.domain.repository.AuthRepository
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
    fun provideYandexDiskRepository(
        authRepository: AuthRepository
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(authRepository)
    }
}
