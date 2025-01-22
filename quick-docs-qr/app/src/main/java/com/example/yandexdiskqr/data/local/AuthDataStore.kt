// ./src/main/java/com/example/yandexdiskqr/data/local/AuthDataStore.kt
package com.example.yandexdiskqr.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore

private val Context.authDataStore: DataStore<Preferences> by preferencesDataStore(name = "auth_prefs")

