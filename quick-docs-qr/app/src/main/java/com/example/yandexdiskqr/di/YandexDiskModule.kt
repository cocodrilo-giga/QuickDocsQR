package com.example.yandexdiskqr.di

import com.example.yandexdiskqr.data.repository.YandexDiskRepositoryImpl
import com.example.yandexdiskqr.domain.repository.AuthRepository
import com.example.yandexdiskqr.domain.repository.YandexDiskRepository
import com.yandex.disk.rest.RestClient
import com.yandex.disk.rest.retrofit.RequestInterceptor
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object YandexDiskModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(authRepository: AuthRepository): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(Interceptor { chain ->
                val token = runBlocking { authRepository.getAuthToken() }
                val request = chain.request().newBuilder()
                    .addHeader("Authorization", "OAuth $token")
                    .build()
                chain.proceed(request)
            })
            .build()
    }

    @Provides
    @Singleton
    fun provideRestClient(okHttpClient: OkHttpClient): RestClient {
        return RestClient.Builder()
            .setHttpClient(okHttpClient)
            .build()
    }

    @Provides
    @Singleton
    fun provideYandexDiskRepository(
        restClient: RestClient,
        authRepository: AuthRepository
    ): YandexDiskRepository {
        return YandexDiskRepositoryImpl(restClient, authRepository)
    }
}
