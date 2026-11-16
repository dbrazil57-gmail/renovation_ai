// Read only an isolated copy of Flutter's cached IndexedDB profile. Export
// validated portable backups; never point Chrome at the original cache.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

// Recovery is tied to the installed Hive CE 2.23.x browser encoding. Validate
// every recovered project using our ordinary backup decoder before writing it.
// ignore: implementation_imports
import 'package:hive_ce/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive_ce/src/registry/type_registry_impl.dart';
import 'package:renovision_ai/models.dart';
import 'package:renovision_ai/project_backup.dart';

Object? decodeBrowserValue(dynamic value) {
  if (value is! Map) throw const FormatException('Invalid browser value.');
  if (value['kind'] == 'plain') return value['data'];
  if (value['kind'] != 'bytes' || value['data'] is! String) {
    throw const FormatException('Unsupported browser value.');
  }
  final bytes = base64Decode(value['data'] as String);
  if (bytes.length >= 2 && bytes[0] == 0x90 && bytes[1] == 0xA9) {
    final reader = BinaryReaderImpl(bytes, TypeRegistryImpl.nullImpl)..skip(2);
    return reader.read();
  }
  return bytes;
}

List<ProjectBackup> backupsFromBrowserDump(Map<String, dynamic> dump) {
  Map<String, Object?> decodeBox(String key) {
    final raw = dump[key];
    if (raw is! Map) throw const FormatException('Missing browser box.');
    return raw.map(
      (key, value) => MapEntry(key as String, decodeBrowserValue(value)),
    );
  }

  final records = decodeBox('records');
  final photoValues = decodeBox('photos');
  final projects = records.entries
      .where((e) => e.key.startsWith('project:'))
      .map((e) => RenovationProject.fromMap(e.value as Map))
      .toList();
  final rooms = records.entries
      .where((e) => e.key.startsWith('room:'))
      .map((e) => RenovationRoom.fromMap(e.value as Map))
      .toList();
  final designs = records.entries
      .where((e) => e.key.startsWith('design:'))
      .map((e) => DesignVersion.fromMap(e.value as Map))
      .toList();
  return projects.map((project) {
    final projectRooms = rooms.where((r) => r.projectId == project.id).toList();
    final roomIds = projectRooms.map((r) => r.id).toSet();
    final projectDesigns = designs
        .where((d) => roomIds.contains(d.roomId))
        .toList();
    final ids = <String>{
      ...projectRooms.expand((r) => r.photoIds),
      ...projectDesigns.map((d) => d.imageId),
      ...projectDesigns.map((d) => d.sourceImageId).whereType<String>(),
      ...projectDesigns.expand((d) => d.supportingImageIds),
      ...projectRooms.map((r) => r.analysis?.sourceImageId).whereType<String>(),
      ...projectRooms.expand(
        (r) => r.analysis?.supportingImageIds ?? const <String>[],
      ),
    };
    final backup = ProjectBackup(
      project: project,
      rooms: projectRooms,
      designs: projectDesigns,
      photos: {
        for (final id in ids)
          id: photoValues[id] is Uint8List
              ? photoValues[id] as Uint8List
              : throw const BackupFailure('A cached project image is missing.'),
      },
    );
    return ProjectBackup.decode(backup.encode());
  }).toList();
}

Future<void> copyDirectory(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entry in source.list(followLinks: false)) {
    final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (entry is Directory) {
      await copyDirectory(entry, Directory('${target.path}/$name'));
    } else if (entry is File) {
      await entry.copy('${target.path}/$name');
    } else {
      throw StateError('Refusing to follow a link in the cached profile.');
    }
  }
}

String recoveryPage(String nonce) =>
    '''<!doctype html><meta charset="utf-8">
<title>Renovision isolated recovery</title><script>
(async () => {
  const names = new Set((await indexedDB.databases()).map(db => db.name));
  function pack(value) {
    if (value instanceof ArrayBuffer || ArrayBuffer.isView(value)) {
      const bytes = value instanceof ArrayBuffer ? new Uint8Array(value) : new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
      let binary = '';
      for (let i = 0; i < bytes.length; i += 16384) binary += String.fromCharCode(...bytes.subarray(i, i + 16384));
      return {kind: 'bytes', data: btoa(binary)};
    }
    return {kind: 'plain', data: value};
  }
  async function read(name) {
    if (!names.has(name)) return {};
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(name);
      request.onupgradeneeded = () => { request.transaction.abort(); reject(new Error('Missing database')); };
      request.onerror = () => reject(new Error('Open failed'));
      request.onsuccess = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains('box')) { db.close(); reject(new Error('Missing box')); return; }
        const transaction = db.transaction('box', 'readonly');
        const store = transaction.objectStore('box');
        const keys = store.getAllKeys(), values = store.getAll();
        transaction.oncomplete = () => {
          const result = {};
          keys.result.forEach((key, i) => result[key] = pack(values.result[i]));
          db.close(); resolve(result);
        };
        transaction.onerror = () => { db.close(); reject(new Error('Read failed')); };
      };
    });
  }
  const payload = {records: await read('renovision_records_v1'), photos: await read('renovision_photo_bytes_v1')};
  await fetch('/dump/$nonce', {method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(payload)});
  document.body.textContent = 'Read completed from isolated copy.';
})().catch(async () => { await fetch('/dump/$nonce', {method:'POST',body:JSON.stringify({error:'Read failed'})}); });
</script>''';

Future<Map<String, dynamic>> readIsolatedPort(
  int port,
  Directory profile,
  String chrome,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final nonce = List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final result = Completer<Map<String, dynamic>>();
  server.listen((request) async {
    try {
      request.response.headers.set('Cache-Control', 'no-store');
      if (request.method == 'GET' && request.uri.path == '/') {
        request.response.headers.contentType = ContentType.html;
        request.response.write(recoveryPage(nonce));
      } else if (request.method == 'POST' &&
          request.uri.path == '/dump/$nonce') {
        final bytes = <int>[];
        await for (final chunk in request) {
          if (bytes.length + chunk.length > ProjectBackup.maxFileBytes) {
            throw const FormatException();
          }
          bytes.addAll(chunk);
        }
        final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        if (!result.isCompleted) result.complete(data);
        request.response.write('Read received.');
      } else {
        request.response.statusCode = 404;
      }
    } catch (error) {
      if (!result.isCompleted) {
        result.completeError(StateError('Isolated browser read failed.'));
      }
    } finally {
      await request.response.close();
    }
  });
  Process? browser;
  try {
    browser = await Process.start(chrome, [
      '--headless=new',
      '--disable-background-networking',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-extensions',
      '--user-data-dir=${profile.absolute.path}',
      'http://localhost:$port/',
    ]);
    unawaited(browser.stdout.drain<void>());
    unawaited(browser.stderr.drain<void>());
    return await result.future.timeout(const Duration(seconds: 25));
  } finally {
    browser?.kill(); // Only the browser process started above, using our unique copy.
    await server.close(force: true);
  }
}

Future<void> main() async {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml').existsSync()) {
    stderr.writeln('Run from the Renovision project folder.');
    exitCode = 1;
    return;
  }
  final source = Directory(
    '${root.path}/.dart_tool/chrome-device/Default/IndexedDB',
  );
  if (!source.existsSync()) {
    stderr.writeln(
      'No cached Flutter browser databases found. Nothing changed.',
    );
    exitCode = 1;
    return;
  }
  final chrome = File(
    '${Platform.environment['PROGRAMFILES']}/Google/Chrome/Application/chrome.exe',
  );
  if (!chrome.existsSync()) {
    stderr.writeln(
      'Chrome is not installed at its standard Windows path. Nothing changed.',
    );
    exitCode = 1;
    return;
  }
  final ports = <int>{};
  await for (final entry in source.list(followLinks: false)) {
    final match = RegExp(r'http_localhost_(\d+)\.indexeddb\.leveldb$')
        .firstMatch(entry.path);
    if (entry is Directory && match != null) ports.add(int.parse(match[1]!));
  }
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(
    RegExp('[^0-9]'),
    '',
  );
  final output = Directory(
    '${root.path}/.local_backups/browser-recovery-$stamp',
  );
  final snapshot = Directory('${output.path}/snapshot/Default/IndexedDB');
  await copyDirectory(source, snapshot);
  final exports = await Directory(
    '${root.path}/recovered_projects/browser-recovery-$stamp',
  ).create(recursive: true);
  final report = <Map<String, dynamic>>[];
  for (final port in ports.toList()..sort()) {
    final working = Directory('${output.path}/working-$port');
    await copyDirectory(
      snapshot,
      Directory('${working.path}/Default/IndexedDB'),
    );
    try {
      final dump = await readIsolatedPort(port, working, chrome.path);
      final backups = backupsFromBrowserDump(dump);
      var index = 0;
      for (final backup in backups) {
        final file = File(
          '${exports.path}/port-$port-project-${++index}.renovision.json',
        );
        await file.writeAsBytes(backup.encode(), flush: true);
      }
      final item = {
        'port': port,
        'projects': backups.length,
        'rooms': backups.fold<int>(0, (n, b) => n + b.rooms.length),
        'designs': backups.fold<int>(0, (n, b) => n + b.designs.length),
      };
      report.add(item);
      stdout.writeln(jsonEncode(item));
    } catch (error) {
      report.add({
        'port': port,
        'error': error is SocketException
            ? 'Port busy; skipped without stopping its process.'
            : 'Recovery failed; original and snapshot retained.',
      });
      stdout.writeln('Port $port skipped. Original and snapshot retained.');
    }
  }
  await File('${output.path}/report.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
    flush: true,
  );
  stdout.writeln('Validated backup copies: ${exports.path}');
  stdout.writeln(
    'Original Chrome cache was never opened by the recovery browser or modified.',
  );
}
