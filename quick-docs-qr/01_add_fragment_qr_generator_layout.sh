#!/usr/bin/env bash
set -e

echo "=== 01. Добавляем layout-файл fragment_qr_generator.xml ==="

# Создадим нужную папку на всякий случай
mkdir -p ./app/src/main/res/layout

# Записываем содержимое
cat << 'EOF' > ./app/src/main/res/layout/fragment_qr_generator.xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/qrGeneratorRoot"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="16dp">

    <!-- Поле для ввода пути к папке -->
    <EditText
        android:id="@+id/folderPathInput"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:hint="@string/folders"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"/>

    <!-- Кнопка для генерации QR -->
    <com.google.android.material.button.MaterialButton
        android:id="@+id/generateButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/generate_qr"
        app:layout_constraintTop_toBottomOf="@id/folderPathInput"
        app:layout_constraintStart_toStartOf="parent"
        android:layout_marginTop="16dp"/>

    <!-- ImageView для отображения сгенерированного QR-кода -->
    <ImageView
        android:id="@+id/qrImage"
        android:layout_width="250dp"
        android:layout_height="250dp"
        android:layout_marginTop="16dp"
        app:layout_constraintTop_toBottomOf="@id/generateButton"
        app:layout_constraintStart_toStartOf="parent"
        android:visibility="gone"/>

    <!-- Кнопка для «Поделиться» QR-кодом -->
    <com.google.android.material.button.MaterialButton
        android:id="@+id/shareQrButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/share_qr_code"
        android:layout_marginTop="16dp"
        android:visibility="gone"
        app:layout_constraintTop_toBottomOf="@id/qrImage"
        app:layout_constraintStart_toStartOf="parent"/>

    <!-- Прогресс-бар для отображения состояния генерации (опционально) -->
    <com.google.android.material.progressindicator.CircularProgressIndicator
        android:id="@+id/progressBar"
        android:layout_width="48dp"
        android:layout_height="48dp"
        android:visibility="gone"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_margin="16dp"/>

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

echo "Done. Created/updated fragment_qr_generator.xml successfully."
