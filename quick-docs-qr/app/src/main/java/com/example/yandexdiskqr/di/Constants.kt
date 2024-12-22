package com.example.yandexdiskqr.di

object Constants {
    // Эти значения нужно заменить на реальные после регистрации приложения
    // в кабинете разработчика Яндекса: https://oauth.yandex.ru/
    const val CLIENT_ID = "PUT_YOUR_CLIENT_ID_HERE"
    const val CLIENT_SECRET = "PUT_YOUR_CLIENT_SECRET_HERE"
    const val REDIRECT_URI = "ydiskqr://auth"
    
    // Эндпоинты OAuth Яндекса
    const val AUTH_URL = "https://oauth.yandex.ru/authorize"
    const val TOKEN_URL = "https://oauth.yandex.ru/token"
}
