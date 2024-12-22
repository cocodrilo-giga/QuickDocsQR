#!/bin/bash

# Создаем директории для утилит и общих компонентов
mkdir -p app/src/main/java/com/example/yandexdiskqr/presentation/common
mkdir -p app/src/main/java/com/example/yandexdiskqr/util
mkdir -p app/src/main/res/anim

# Создаем анимации
cat > ./app/src/main/res/anim/slide_in_right.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <translate
        android:duration="300"
        android:fromXDelta="100%"
        android:toXDelta="0%" />
</set>
EOL

cat > ./app/src/main/res/anim/slide_out_left.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<set xmlns:android="http://schemas.android.com/apk/res/android">
    <translate
        android:duration="300"
        android:fromXDelta="0%"
        android:toXDelta="-100%" />
</set>
EOL

# Создаем NetworkResult.kt для обработки сетевых запросов
cat > ./app/src/main/java/com/example/yandexdiskqr/util/NetworkResult.kt << 'EOL'
package com.example.yandexdiskqr.util

sealed class NetworkResult<out T> {
    data class Success<out T>(val data: T) : NetworkResult<T>()
    data class Error(val message: String) : NetworkResult<Nothing>()
    object Loading : NetworkResult<Nothing>()
}
EOL

# Создаем ErrorHandler.kt для централизованной обработки ошибок
cat > ./app/src/main/java/com/example/yandexdiskqr/util/ErrorHandler.kt << 'EOL'
package com.example.yandexdiskqr.util

import android.content.Context
import com.example.yandexdiskqr.R
import com.yandex.disk.rest.exceptions.ServerIOException
import com.yandex.disk.rest.exceptions.UnauthorizedException
import java.net.UnknownHostException
import javax.inject.Inject

class ErrorHandler @Inject constructor(
    private val context: Context
) {
    fun getErrorMessage(throwable: Throwable): String {
        return when (throwable) {
            is UnauthorizedException -> context.getString(R.string.error_unauthorized)
            is ServerIOException -> context.getString(R.string.error_server)
            is UnknownHostException -> context.getString(R.string.error_network)
            else -> throwable.message ?: context.getString(R.string.error_unknown)
        }
    }
}
EOL

# Создаем LoadingButton.kt для улучшенной обратной связи
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/common/LoadingButton.kt << 'EOL'
package com.example.yandexdiskqr.presentation.common

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.FrameLayout
import androidx.core.view.isVisible
import com.example.yandexdiskqr.databinding.ViewLoadingButtonBinding

class LoadingButton @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val binding = ViewLoadingButtonBinding.inflate(
        LayoutInflater.from(context),
        this,
        true
    )

    var isLoading: Boolean = false
        set(value) {
            field = value
            binding.progressBar.isVisible = value
            binding.button.isEnabled = !value
        }

    init {
        isLoading = false
    }

    fun setOnClickListener(listener: OnClickListener) {
        binding.button.setOnClickListener(listener)
    }

    fun setText(text: CharSequence) {
        binding.button.text = text
    }
}
EOL

# Создаем layout для LoadingButton
cat > ./app/src/main/res/layout/view_loading_button.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<merge xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="wrap_content">

    <com.google.android.material.button.MaterialButton
        android:id="@+id/button"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:minHeight="56dp" />

    <com.google.android.material.progressindicator.CircularProgressIndicator
        android:id="@+id/progressBar"
        android:layout_width="24dp"
        android:layout_height="24dp"
        android:layout_gravity="center"
        android:indeterminate="true"
        android:visibility="gone"
        app:indicatorColor="?attr/colorPrimary" />

</merge>
EOL

# Обновляем strings.xml для новых ошибок
cat >> ./app/src/main/res/values/strings.xml << 'EOL'
    <string name="error_unauthorized">Необходима повторная авторизация</string>
    <string name="error_server">Ошибка сервера. Попробуйте позже</string>
    <string name="error_network">Проверьте подключение к интернету</string>
    <string name="error_unknown">Произошла неизвестная ошибка</string>
    <string name="retry">Повторить</string>
EOL

# Создаем BaseViewModel.kt для общей логики
cat > ./app/src/main/java/com/example/yandexdiskqr/presentation/common/BaseViewModel.kt << 'EOL'
package com.example.yandexdiskqr.presentation.common

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.example.yandexdiskqr.util.ErrorHandler
import kotlinx.coroutines.CancellationException

abstract class BaseViewModel(
    private val errorHandler: ErrorHandler
) : ViewModel() {

    protected val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    protected fun handleError(throwable: Throwable) {
        if (throwable !is CancellationException) {
            _error.value = errorHandler.getErrorMessage(throwable)
        }
    }

    fun clearError() {
        _error.value = null
    }
}
EOL

# Обновляем FoldersFragment для поддержки Pull-to-Refresh
cat > ./app/src/main/res/layout/fragment_folders.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <androidx.swiperefreshlayout.widget.SwipeRefreshLayout
        android:id="@+id/swipeRefresh"
        android:layout_width="0dp"
        android:layout_height="0dp"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintTop_toTopOf="parent">

        <androidx.recyclerview.widget.RecyclerView
            android:id="@+id/recyclerView"
            android:layout_width="match_parent"
            android:layout_height="match_parent"
            android:clipToPadding="false"
            android:padding="8dp" />

    </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>

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

# Добавляем обработку состояния в навигацию
cat > ./app/src/main/res/navigation/nav_graph.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<navigation xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/nav_graph"
    app:startDestination="@id/foldersFragment">

    <fragment
        android:id="@+id/foldersFragment"
        android:name="com.example.yandexdiskqr.presentation.folders.FoldersFragment"
        android:label="@string/folders">
        <action
            android:id="@+id/action_folders_to_qr"
            app:destination="@id/qrGeneratorFragment"
            app:enterAnim="@anim/slide_in_right"
            app:exitAnim="@anim/slide_out_left" />
    </fragment>

    <fragment
        android:id="@+id/scannerFragment"
        android:name="com.example.yandexdiskqr.presentation.scanner.ScannerFragment"
        android:label="@string/scanner">
        <action
            android:id="@+id/action_scanner_to_viewer"
            app:destination="@id/viewerFragment"
            app:enterAnim="@anim/slide_in_right"
            app:exitAnim="@anim/slide_out_left" />
    </fragment>

    <fragment
        android:id="@+id/viewerFragment"
        android:name="com.example.yandexdiskqr.presentation.viewer.ViewerFragment"
        android:label="@string/viewer">
        <argument
            android:name="folderPath"
            app:argType="string" />
    </fragment>

</navigation>
EOL

# Обновляем зависимости в build.gradle.kts
cat >> ./app/build.gradle.kts << 'EOL'
dependencies {
    implementation("androidx.swiperefreshlayout:swiperefreshlayout:1.1.0")
}
EOL
