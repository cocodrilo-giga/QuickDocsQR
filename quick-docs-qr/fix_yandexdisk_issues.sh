#!/usr/bin/env bash
set -e

##############################################################################
# 1. Добавляем CLIENT_SECRET в Constants.kt
##############################################################################
echo "Fix #1: Adding CLIENT_SECRET to Constants.kt ..."

# Добавляем строчку прямо после 'object Constants {'
# На macOS нужно указывать -i '' для sed.
sed -i '' '/object Constants {/a\
    const val CLIENT_SECRET = "your_client_secret_here"
' ./app/src/main/java/com/example/yandexdiskqr/di/Constants.kt

##############################################################################
# 2. Пробрасываем authRepository в YandexDiskModule
##############################################################################
echo "Fix #2: Passing authRepository to YandexDiskRepositoryImpl in YandexDiskModule.kt ..."

# Меняем сигнатуру метода provideYandexDiskRepository
sed -i '' -E 's/fun provideYandexDiskRepository\( *restClient: RestClient *\): YandexDiskRepository /fun provideYandexDiskRepository(\n        restClient: RestClient,\n        authRepository: AuthRepository\n    ): YandexDiskRepository /' ./app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt

# Меняем вызов конструктора YandexDiskRepositoryImpl
sed -i '' 's/return YandexDiskRepositoryImpl(restClient)/return YandexDiskRepositoryImpl(restClient, authRepository)/' ./app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt

echo "Done! Now your project should compile and run without these errors."
echo "IMPORTANT: Don't forget to replace \"your_client_secret_here\" with your real CLIENT_SECRET."
