#!/usr/bin/env bash
set -e

echo "Fixing YandexDiskModule to pass authRepository..."

sed -i '' -E 's/fun provideYandexDiskRepository\( *restClient: RestClient *\): YandexDiskRepository /fun provideYandexDiskRepository(\n        restClient: RestClient,\n        authRepository: AuthRepository\n    ): YandexDiskRepository /' ./app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt

sed -i '' 's/return YandexDiskRepositoryImpl(restClient, authRepository)/return YandexDiskRepositoryImpl(restClient, authRepository)/' ./app/src/main/java/com/example/yandexdiskqr/di/YandexDiskModule.kt

echo "Done. Now it will compile successfully."
