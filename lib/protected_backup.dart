import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import 'project_backup.dart';

const _magic = [82, 86, 69, 78, 67, 48, 49, 10]; // RVENC01\n
const _iterations = 600000;

bool isProtectedBackup(Uint8List bytes) =>
    bytes.length >= _magic.length &&
    List.generate(
      _magic.length,
      (i) => bytes[i] == _magic[i],
    ).every((same) => same);

Future<Uint8List> protectBackup(Uint8List bytes, String password) =>
    compute(_protect, (bytes, password));

Future<Uint8List> unlockBackup(Uint8List bytes, String password) =>
    compute(_unlock, (bytes, password));

Future<SecretKey> _key(String password, List<int> salt) async {
  final passwordKey = SecretKey(utf8.encode(password));
  try {
    return await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    ).deriveKey(secretKey: passwordKey, nonce: salt);
  } finally {
    passwordKey.destroy();
  }
}

void _checkPassword(String password) {
  if (password.trim().length < 12 || password.length > 1024) {
    throw const BackupFailure(
      'Use a backup password between 12 and 1024 characters.',
    );
  }
}

Future<Uint8List> _protect((Uint8List, String) input) async {
  final (plain, password) = input;
  _checkPassword(password);
  if (plain.isEmpty || plain.length > ProjectBackup.maxFileBytes - 4096) {
    throw const BackupFailure(
      'This project is too large for a protected backup (100 MB file limit).',
    );
  }
  final random = Random.secure();
  final salt = List.generate(16, (_) => random.nextInt(256));
  final algorithm = AesGcm.with256bits();
  final nonce = algorithm.newNonce();
  final metadata = utf8.encode(
    jsonEncode({
      'cipher': 'AES-256-GCM',
      'kdf': 'PBKDF2-SHA256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
    }),
  );
  final prefix = Uint8List(_magic.length + 4 + metadata.length);
  prefix.setAll(0, _magic);
  ByteData.sublistView(prefix).setUint32(_magic.length, metadata.length);
  prefix.setAll(_magic.length + 4, metadata);
  final key = await _key(password, salt);
  try {
    final box = await algorithm.encrypt(
      plain,
      secretKey: key,
      nonce: nonce,
      aad: prefix,
    );
    return (BytesBuilder(copy: false)
          ..add(prefix)
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .takeBytes();
  } finally {
    key.destroy();
  }
}

Future<Uint8List> _unlock((Uint8List, String) input) async {
  final (bytes, password) = input;
  _checkPassword(password);
  if (!isProtectedBackup(bytes) ||
      bytes.length > ProjectBackup.maxFileBytes ||
      bytes.length < 32) {
    throw const BackupFailure(
      'Choose a supported protected RenoVision backup.',
    );
  }
  late final Map<String, dynamic> header;
  late final int offset;
  late final List<int> salt, nonce;
  try {
    final length = ByteData.sublistView(bytes).getUint32(_magic.length);
    offset = _magic.length + 4 + length;
    if (length > 4096 || length < 2 || offset + 16 >= bytes.length) {
      throw const FormatException();
    }
    header = jsonDecode(
      utf8.decode(bytes.sublist(_magic.length + 4, offset)),
    ) as Map<String, dynamic>;
    if (header.length != 5 ||
        header['cipher'] != 'AES-256-GCM' ||
        header['kdf'] != 'PBKDF2-SHA256' ||
        header['iterations'] != _iterations) {
      throw const FormatException();
    }
    salt = base64Decode(header['salt'] as String);
    nonce = base64Decode(header['nonce'] as String);
    if (salt.length != 16 || nonce.length != 12) throw const FormatException();
  } catch (_) {
    throw const BackupFailure(
      'This protected backup has an invalid or unsupported header.',
    );
  }
  final key = await _key(password, salt);
  try {
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(
        bytes.sublist(offset, bytes.length - 16),
        nonce: nonce,
        mac: Mac(bytes.sublist(bytes.length - 16)),
      ),
      secretKey: key,
      aad: bytes.sublist(0, offset),
    );
    return Uint8List.fromList(clear);
  } on SecretBoxAuthenticationError {
    throw const BackupFailure(
      'The password did not unlock this backup, or the file was changed or damaged.',
    );
  } finally {
    key.destroy();
  }
}
