Да, для Android-приложения SHA256 Fingerprint обязателен. Это цифровой отпечаток, который используется для идентификации вашего приложения.
Чтобы получить SHA256 Fingerprint:

Откройте терминал
Перейдите в папку с проектом
Выполните команду для debug-версии:

bashCopykeytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
Или для release-версии используйте путь к вашему keystore файлу:
bashCopykeytool -list -v -keystore path_to_your_release_keystore

В выводе найдите строку, которая начинается с "SHA256:". Скопируйте этот отпечаток и вставьте его в поле "SHA256 Fingerprints" в консоли Яндекс.OAuth.

Для debug-версии по умолчанию используются:

Пароль keystore: android
Пароль ключа: android
Alias: androiddebugkey

Важно: если вы планируете публиковать приложение в Google Play, вам нужно будет также добавить SHA256 Fingerprint от release-keystore.
После добавления отпечатка можно продолжать настройку приложения в консоли Яндекс.OAuth.