// ./src/main/java/com/example/yandexdiskqr/di/AuthModule.kt
package com.example.yandexdiskqr.di

import android.content.Context
import com.example.yandexdiskqr.data.repository.AuthRepositoryImpl
import com.example.yandexdiskqr.data.repository.SecureStorageImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AuthModule {

    @Provides
    @Singleton
    fun provideSecureStorage(
        @ApplicationContext context: Context
    ): SecureStorageImpl = SecureStorageImpl(context)

    @Provides
    @Singleton
    fun provideAuthRepository(
        secureStorage: SecureStorageImpl
    ): AuthRepository = AuthRepositoryImpl(secureStorage)
}
