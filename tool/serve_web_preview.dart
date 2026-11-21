import 'dart:io';

const _mimeTypes = {
  'html': 'text/html; charset=utf-8',
  'js': 'application/javascript; charset=utf-8',
  'json': 'application/json',
  'css': 'text/css',
  'wasm': 'application/wasm',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'ico': 'image/x-icon',
  'mp4': 'video/mp4',
  'ttf': 'font/ttf',
  'otf': 'font/otf',
  'woff': 'font/woff',
  'woff2': 'font/woff2',
};

/// Local release preview with byte ranges for seekable bundled help videos.
/// Serves only the compiled public web bundle; never app data or project files.
Future<HttpServer> serveWebPreview(
  Directory directory, {
  int port = 7357,
}) async {
  final root = await directory.resolveSymbolicLinks();
  String identity(String path) =>
      Platform.isWindows ? path.toLowerCase() : path;
  final prefix = '${identity(root)}${Platform.pathSeparator}';
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  server.listen((request) async {
    final response = request.response;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        response.headers.set('Allow', 'GET, HEAD');
        return;
      }
      final segments = request.uri.path == '/'
          ? ['index.html']
          : request.uri.pathSegments;
      if (segments.any(
        (part) =>
            part == '.' ||
            part == '..' ||
            part.contains('/') ||
            RegExp(r'[:\\\x00-\x1f]').hasMatch(part),
      )) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      final file = File('$root/${segments.join('/')}');
      if (!await file.exists()) {
        response.statusCode = HttpStatus.notFound;
        return;
      }
      final resolved = await file.resolveSymbolicLinks();
      if (!identity(resolved).startsWith(prefix)) {
        response.statusCode = HttpStatus.forbidden;
        return;
      }
      final length = await file.length();
      response.headers.set(
        'Content-Type',
        _mimeTypes[file.path.split('.').last.toLowerCase()] ??
            'application/octet-stream',
      );
      response.headers.set('Cache-Control', 'no-store');
      response.headers.set('Accept-Ranges', 'bytes');
      var start = 0, end = length - 1;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) {
        final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range.trim());
        if (match == null ||
            length == 0 ||
            (match[1]!.isEmpty && match[2]!.isEmpty)) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set('Content-Range', 'bytes */$length');
          return;
        }
        if (match[1]!.isEmpty) {
          final suffix = int.tryParse(match[2]!) ?? 0;
          start = (length - suffix).clamp(0, length);
        } else {
          start = int.tryParse(match[1]!) ?? length;
          if (match[2]!.isNotEmpty) {
            end = (int.tryParse(match[2]!) ?? -1).clamp(-1, length - 1);
          }
        }
        if (start >= length || end < start) {
          response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          response.headers.set('Content-Range', 'bytes */$length');
          return;
        }
        response.statusCode = HttpStatus.partialContent;
        response.headers.set('Content-Range', 'bytes $start-$end/$length');
      }
      response.contentLength = length == 0 ? 0 : end - start + 1;
      if (request.method == 'GET' && length > 0) {
        await response.addStream(File(resolved).openRead(start, end + 1));
      }
    } catch (_) {
      // A disconnected media seek must not terminate the preview server.
      try {
        response.statusCode = HttpStatus.internalServerError;
      } catch (_) {}
    } finally {
      try {
        await response.close();
      } catch (_) {}
    }
  });
  return server;
}

Future<void> main(List<String> arguments) async {
  final port = arguments.isEmpty ? 7357 : int.parse(arguments.single);
  if (port < 1024 || port > 65535 || port == 8787) {
    throw ArgumentError(
      'Choose a preview port from 1024–65535 other than relay port 8787.',
    );
  }
  await serveWebPreview(Directory('build/web'), port: port);
  stdout.writeln('RenoVision desktop release preview: http://localhost:$port');
  stdout.writeln(
    'Keep the same Chrome address/profile. Ctrl+C stops this server.',
  );
}
