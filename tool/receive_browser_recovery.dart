// Temporary loopback-only recovery. No provider key, AI request or browser
// profile mutation. Run from the project workspace; stop after one valid copy.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync()) {
    throw StateError('Run in the app workspace.');
  }
  const origin = 'http://localhost:7357';
  final nonce = List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final destination = Directory(
    'recovered_projects/live-browser-${DateTime.now().millisecondsSinceEpoch}',
  );
  var saved = false;
  final timeout = Timer(const Duration(minutes: 30), () {
    server.close(force: true);
  });
  final template = await File('tool/local_project_recovery.html')
      .readAsString();
  final receiver = 'http://127.0.0.1:${server.port}/recover/$nonce';
  await File('build/web/local-project-recovery.html').writeAsString(
    template.replaceFirst(
      '<script>',
      '<script>window.RENOVISION_RECOVERY_RECEIVER=${jsonEncode(receiver)};</script><script>',
    ),
  );
  await File('output/recovery-receiver.local.json').writeAsString(
    jsonEncode({'port': server.port, 'directory': destination.absolute.path}),
  );
  stdout.writeln(
    'Local recovery ready at http://localhost:7357/local-project-recovery.html. The app tab need not reload.',
  );
  try {
    await for (final request in server) {
      final response = request.response;
      response.headers.set('Cache-Control', 'no-store');
      if (request.headers.value('origin') != origin ||
          request.uri.path != '/recover/$nonce' ||
          saved) {
        response.statusCode = 403;
        await response.close();
        continue;
      }
      response.headers.set('Access-Control-Allow-Origin', origin);
      response.headers.set('Vary', 'Origin');
      if (request.method == 'OPTIONS') {
        response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
        response.statusCode = 204;
        await response.close();
        continue;
      }
      if (request.method != 'POST') {
        response.statusCode = 405;
        await response.close();
        continue;
      }
      try {
        final bytes = <int>[];
        await for (final chunk in request) {
          if (bytes.length + chunk.length > 100 * 1024 * 1024) {
            throw const FormatException('Recovery too large');
          }
          bytes.addAll(chunk);
        }
        final data = jsonDecode(utf8.decode(bytes));
        if (data is! Map ||
            data['format'] != 'renovision.browser-recovery' ||
            data['version'] != 1 ||
            data['origin'] != origin ||
            data['records'] is! Map ||
            data['photos'] is! Map) {
          throw const FormatException('Invalid recovery');
        }
        final records = data['records'] as Map, photos = data['photos'] as Map;
        if (records.isEmpty ||
            records.keys.any(
              (key) =>
                  key is! String ||
                  !RegExp(r'^(project:|room:|design:)').hasMatch(key),
            )) {
          throw const FormatException('Only project records are accepted');
        }
        final projects = records.keys
            .where((key) => (key as String).startsWith('project:'))
            .length;
        if (projects == 0 || photos.isEmpty) {
          throw const FormatException('Missing saved data');
        }
        await destination.create(recursive: true);
        await File('${destination.path}/browser-dump.json')
            .writeAsBytes(bytes, flush: true);
        saved = true;
        response.headers.contentType = ContentType.json;
        response.write(
          jsonEncode({
            'projects': projects,
            'images': photos.length,
            'location': destination.absolute.path,
          }),
        );
        await response.close();
        stdout.writeln(
          'Private raw recovery saved: ${destination.path}/browser-dump.json ($projects projects, ${photos.length} stored images). No settings or provider requests.',
        );
        break;
      } catch (_) {
        response.statusCode = 400;
        response.write(
          'Recovery could not be saved. Original browser data is unchanged.',
        );
        await response.close();
      }
    }
  } finally {
    timeout.cancel();
    await server.close(force: true);
  }
}
