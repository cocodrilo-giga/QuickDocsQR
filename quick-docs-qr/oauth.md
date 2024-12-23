Для запуска приложения нужно сделать следующее:

Зарегистрировать приложение в консоли Яндекс.OAuth:

Перейти на https://oauth.yandex.ru/
Создать новое приложение
В настройках приложения указать redirect URI: ydiskqr://auth
Запросить разрешения для работы с Яндекс.Диском (доступ к папкам и файлам)


Получить необходимые ключи:

CLIENT_ID (будет выдан после регистрации приложения)
CLIENT_SECRET (будет выдан после регистрации приложения)


Заменить значения в файле Constants.kt:

kotlinCopyobject Constants {
const val CLIENT_ID = "ваш_client_id"
const val CLIENT_SECRET = "ваш_client_secret"
const val REDIRECT_URI = "ydiskqr://auth"  // оставить как есть
const val OAUTH_URL = "https://oauth.yandex.ru/authorize"  // оставить как есть
const val TOKEN_URL = "https://oauth.yandex.ru/token"  // оставить как есть
}

Запустить все предоставленные скрипты по порядку:

fix-base-config (настройка базовой конфигурации)
auth-implementation (реализация авторизации)
qr-code-implementation (реализация работы с QR-кодами)
user-experience-improvements (улучшения UI/UX)
security-improvements (улучшения безопасности)


Собрать и запустить приложение

После этого приложение будет полностью готово к работе и будет предоставлять следующий функционал:

Авторизация через Яндекс
Просмотр папок на Яндекс.Диске
Генерация QR-кодов для папок
Сканирование QR-кодов камерой
Безопасное хранение данных авторизации
Автоматическое обновление токенов
Обработка всех возможных ошибок
Современный Material Design интерфейс

Все файлы будут размещены в правильной структуре проекта, и приложение будет готово к компиляции и запуску.