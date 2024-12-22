package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.security.AuthManager
import com.example.yandexdiskqr.security.EncryptedStorage
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object SecurityModule {

    @Provides
    @Singleton
    fun provideAuthManager(
        encryptedStorage: EncryptedStorage
    ): AuthManager = AuthManager(encryptedStorage)
}
