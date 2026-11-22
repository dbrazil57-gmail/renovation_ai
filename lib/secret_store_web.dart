import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'secret_store_types.dart';

SecretStore createSecretStore({String provider = 'openai'}) {
  if (!['openai', 'gemini', 'tester'].contains(provider)) {
    throw ArgumentError('Unsupported provider');
  }
  return BrowserSecretStore(provider);
}

/// A separate same-origin vault, excluded from project and recovery exports.
/// WebCrypto keeps the AES key non-extractable. Same-origin code can still use
/// it: this is device/browser persistence, not protection from a compromised app.
class BrowserSecretStore implements SecretStore {
  final String provider;
  BrowserSecretStore(this.provider);
  static const databaseName = 'renovision_private_vault_v1';
  @override
  bool get persistent => true;

  Future<web.IDBDatabase> _open() {
    final done = Completer<web.IDBDatabase>();
    final opening = web.window.indexedDB.open(databaseName, 1);
    opening.onupgradeneeded = ((web.Event _) {
      (opening.result as web.IDBDatabase).createObjectStore('secrets');
    }).toJS;
    opening.onsuccess = ((web.Event _) {
      if (!done.isCompleted) done.complete(opening.result as web.IDBDatabase);
    }).toJS;
    void failed(web.Event _) {
      if (!done.isCompleted) {
        done.completeError(
          StateError('Browser private storage is unavailable.'),
        );
      }
    }

    opening.onerror = failed.toJS;
    opening.onblocked = failed.toJS;
    return done.future.timeout(const Duration(seconds: 10));
  }

  Future<JSAny?> _operation(
    bool write,
    JSAny? Function(web.IDBObjectStore) action,
  ) async {
    final db = await _open();
    try {
      final done = Completer<JSAny?>();
      final tx = db.transaction(
        'secrets'.toJS,
        write ? 'readwrite' : 'readonly',
      );
      final request = action(tx.objectStore('secrets')) as web.IDBRequest;
      JSAny? result;
      request.onsuccess = ((web.Event _) {
        result = request.result;
      }).toJS;
      tx.oncomplete = ((web.Event _) {
        if (!done.isCompleted) done.complete(result);
      }).toJS;
      void failed(web.Event _) {
        if (!done.isCompleted) {
          done.completeError(StateError('Browser key storage failed.'));
        }
      }

      tx.onabort = failed.toJS;
      tx.onerror = failed.toJS;
      return await done.future.timeout(const Duration(seconds: 10));
    } finally {
      db.close();
    }
  }

  @override
  Future<String?> read() async {
    final value = await _operation(false, (store) => store.get(provider.toJS));
    if (value == null || value.isUndefinedOrNull) return null;
    final record = value as JSObject;
    final plain = await web.window.crypto.subtle
        .decrypt(
          {
            'name': 'AES-GCM',
            'iv': record.getProperty<JSAny>('iv'.toJS),
          }.jsify()!,
          record.getProperty<web.CryptoKey>('key'.toJS),
          record.getProperty<JSArrayBuffer>('cipher'.toJS),
        )
        .toDart;
    return utf8.decode((plain as JSArrayBuffer).toDart.asUint8List());
  }

  @override
  Future<void> write(String secret) async {
    if (!web.window.isSecureContext) {
      throw StateError('Use HTTPS or localhost to remember a key.');
    }
    final crypto = web.window.crypto;
    final key =
        await crypto.subtle
                .generateKey(
                  {'name': 'AES-GCM', 'length': 256}.jsify()!,
                  false,
                  ['encrypt'.toJS, 'decrypt'.toJS].toJS,
                )
                .toDart
            as web.CryptoKey;
    final iv = Uint8List(12).toJS;
    crypto.getRandomValues(iv);
    final cipher = await crypto.subtle
        .encrypt(
          {'name': 'AES-GCM', 'iv': iv}.jsify()!,
          key,
          Uint8List.fromList(utf8.encode(secret)).toJS,
        )
        .toDart;
    final record = JSObject()
      ..setProperty('key'.toJS, key)
      ..setProperty('iv'.toJS, iv)
      ..setProperty('cipher'.toJS, cipher);
    await _operation(true, (store) => store.put(record, provider.toJS));
  }

  @override
  Future<void> delete() async {
    await _operation(true, (store) => store.delete(provider.toJS));
  }
}
