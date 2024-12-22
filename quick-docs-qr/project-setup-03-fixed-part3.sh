#!/bin/bash

cd YandexDiskQR

# Создание layout для списка папок
cat > app/src/main/res/layout/fragment_folders.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.recyclerview.widget.RecyclerView
        android:id="@+id/recyclerView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        android:clipToPadding="false"
        android:padding="8dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <com.google.android.material.progressindicator.CircularProgressIndicator
        android:id="@+id/progressBar"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:visibility="gone"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Создание layout для элемента списка папок
cat > app/src/main/res/layout/item_folder.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    android:layout_margin="4dp"
    app:cardCornerRadius="8dp"
    app:cardElevation="2dp">

    <androidx.constraintlayout.widget.ConstraintLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:padding="16dp">

        <ImageView
            android:id="@+id/folderIcon"
            android:layout_width="24dp"
            android:layout_height="24dp"
            android:src="@drawable/ic_folder"
            app:layout_constraintBottom_toBottomOf="parent"
            app:layout_constraintStart_toStartOf="parent"
            app:layout_constraintTop_toTopOf="parent"
            app:tint="?attr/colorPrimary" />

        <TextView
            android:id="@+id/folderName"
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_marginStart="16dp"
            android:layout_marginEnd="16dp"
            android:textAppearance="?attr/textAppearanceSubtitle1"
            app:layout_constraintBottom_toBottomOf="parent"
            app:layout_constraintEnd_toStartOf="@+id/generateQrButton"
            app:layout_constraintStart_toEndOf="@+id/folderIcon"
            app:layout_constraintTop_toTopOf="parent" />

        <ImageButton
            android:id="@+id/generateQrButton"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:padding="8dp"
            android:src="@drawable/ic_qr_code"
            app:layout_constraintBottom_toBottomOf="parent"
            app:layout_constraintEnd_toEndOf="parent"
            app:layout_constraintTop_toTopOf="parent"
            app:tint="?attr/colorPrimary" />

    </androidx.constraintlayout.widget.ConstraintLayout>

</com.google.android.material.card.MaterialCardView>
EOL

# Создание layout для сканера QR-кодов
cat > app/src/main/res/layout/fragment_scanner.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.camera.view.PreviewView
        android:id="@+id/previewView"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <View
        android:id="@+id/scannerOverlay"
        android:layout_width="200dp"
        android:layout_height="200dp"
        android:background="@drawable/scanner_overlay"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

    <TextView
        android:id="@+id/scannerHint"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="32dp"
        android:text="@string/scan_qr"
        android:textAppearance="?attr/textAppearanceSubtitle1"
        android:textColor="@android:color/white"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toBottomOf="@id/scannerOverlay" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOL

# Создание drawable для оверлея сканера
mkdir -p app/src/main/res/drawable
cat > app/src/main/res/drawable/scanner_overlay.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <stroke
        android:width="2dp"
        android:color="?attr/colorPrimary" />
    <corners android:radius="8dp" />
</shape>
EOL

# Создание иконок
cat > app/src/main/res/drawable/ic_folder.xml << 'EOL'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#000000"
        android:pathData="M10,4H4c-1.1,0 -1.99,0.9 -1.99,2L2,18c0,1.1 0.9,2 2,2h16c1.1,0 2,-0.9 2,-2V8c0,-1.1 -0.9,-2 -2,-2h-8l-2,-2z"/>
</vector>
EOL

cat > app/src/main/res/drawable/ic_qr_code.xml << 'EOL'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#000000"
        android:pathData="M3,11h8V3H3V11zM5,5h4v4H5V5z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M3,21h8v-8H3V21zM5,15h4v4H5V15z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M13,3v8h8V3H13zM19,9h-4V5h4V9z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M19,19h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M13,13h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M15,15h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M13,17h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M15,19h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M17,17h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M17,13h2v2h-2z"/>
    <path
        android:fillColor="#000000"
        android:pathData="M19,15h2v2h-2z"/>
</vector>
EOL

cat > app/src/main/res/drawable/ic_qr_scanner.xml << 'EOL'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#000000"
        android:pathData="M9.5,6.5v3h-3v-3h3M11,5H5v6h6V5L11,5zM9.5,14.5v3h-3v-3h3M11,13H5v6h6V13L11,13zM17.5,6.5v3h-3v-3h3M19,5h-6v6h6V5L19,5zM13,13h1.5v1.5H13V13zM14.5,14.5H16V16h-1.5V14.5zM16,13h1.5v1.5H16V13zM13,16h1.5v1.5H13V16zM14.5,17.5H16V19h-1.5V17.5zM16,16h1.5v1.5H16V16zM17.5,14.5H19V16h-1.5V14.5zM17.5,17.5H19V19h-1.5V17.5zM22,7h-2V4h-3V2h5V7zM22,22v-5h-2v3h-3v2H22zM2,22h5v-2H4v-3H2V22zM2,2v5h2V4h3V2H2z"/>
</vector>
EOL

# Создание стилей
cat > app/src/main/res/values/themes.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.YandexDiskQR" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/primary</item>
        <item name="colorPrimaryVariant">@color/primary_dark</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/secondary</item>
        <item name="colorSecondaryVariant">@color/secondary_dark</item>
        <item name="colorOnSecondary">@color/black</item>
        <item name="android:statusBarColor">?attr/colorPrimaryVariant</item>
    </style>
</resources>
EOL

# Создание цветов
cat > app/src/main/res/values/colors.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#FF1976D2</color>
    <color name="primary_dark">#FF1565C0</color>
    <color name="secondary">#FF26A69A</color>
    <color name="secondary_dark">#FF00897B</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
EOL

echo "Layouts and resources created successfully!"