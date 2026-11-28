package com.example.renovision_ai

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** The API key is encrypted; its encryption key stays in Android Keystore. */
class KeyVault(context: Context, provider: String = "openai") {
    init { require(provider in setOf("openai", "gemini", "tester", "access")) }
    private val maxLength = if (provider == "access") 16384 else 1024
    private val preferences = context.getSharedPreferences(
        when (provider) { "openai" -> "renovision_secrets"; "tester" -> "renovision_tester_secrets"; "access" -> "renovision_access_secrets"; else -> "renovision_gemini_secrets" }, Context.MODE_PRIVATE)
    private val alias = "renovision_${provider}_key_v1"
    private fun encryptionKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existing = store.getKey(alias, null)
        if (existing is SecretKey) return existing
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)
            .build())
        return generator.generateKey()
    }
    fun write(value: String) {
        require(value.isNotBlank() && value.length <= maxLength)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, encryptionKey())
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        check(preferences.edit()
            .putString("ciphertext", Base64.encodeToString(encrypted, Base64.NO_WRAP))
            .putString("iv", Base64.encodeToString(cipher.iv, Base64.NO_WRAP)).commit())
    }
    fun read(): String? {
        val encrypted = preferences.getString("ciphertext", null) ?: return null
        val iv = preferences.getString("iv", null) ?: error("Missing IV")
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, encryptionKey(), GCMParameterSpec(128, Base64.decode(iv, Base64.NO_WRAP)))
        return String(cipher.doFinal(Base64.decode(encrypted, Base64.NO_WRAP)), Charsets.UTF_8)
    }
    fun delete() { check(preferences.edit().clear().commit()) }
}
