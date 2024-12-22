package com.example.yandexdiskqr.di

import android.content.Context
import com.example.yandexdiskqr.data.local.AuthDataStore
import com.example.yandexdiskqr.data.repository.AuthRepositoryImpl
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
    fun provideAuthDataStore(
        @ApplicationContext context: Context
    ): AuthDataStore = AuthDataStore(context)

    @Provides
    @Singleton
    fun provideAuthRepository(
        authDataStore: AuthDataStore
    ): AuthRepository = AuthRepositoryImpl(authDataStore)
}
