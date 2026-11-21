import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/serve_web_preview.dart';

void main() {
  test('desktop release server serves complete files, HEAD and byte ranges without exposing files outside the bundle', () async {
    final output = Directory('output').absolute;
    await output.create(recursive: true);
    final fixture = await output.createTemp('web-preview-test-');
    final public = await Directory('${fixture.path}/public').create();
    await File('${public.path}/index.html')
        .writeAsString('<title>Sample app</title>');
    await File('${fixture.path}/private.txt')
        .writeAsString('outside-public-bundle');
    final media = List<int>.generate(64, (index) => index);
    await File('${public.path}/sample.mp4').writeAsBytes(media);
    await File('${public.path}/empty.bin').writeAsBytes([]);
    final server = await serveWebPreview(public, port: 0);
    final client = HttpClient();
    final base = 'http://127.0.0.1:${server.port}';
    addTearDown(() async {
      client.close(force: true);
      await server.close(force: true);
      final path = await fixture.resolveSymbolicLinks();
      final parent = await output.resolveSymbolicLinks();
      if (!path.startsWith(
        '$parent${Platform.pathSeparator}web-preview-test-',
      )) {
        throw StateError('Refusing to remove an unexpected fixture path.');
      }
      await Directory(path).delete(recursive: true);
    });

    Future<(HttpClientResponse, List<int>)> read(
      String path, {
      String method = 'GET',
      String? range,
    }) async {
      final request = await client.openUrl(method, Uri.parse('$base$path'));
      if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
      final response = await request.close();
      final bytes = await response.fold<List<int>>(
        [],
        (all, chunk) => all..addAll(chunk),
      );
      return (response, bytes);
    }

    final (index, html) = await read('/');
    expect(index.statusCode, 200);
    expect(utf8.decode(html), contains('Sample app'));
    expect(index.headers.contentType!.mimeType, 'text/html');
    final (whole, fullBytes) = await read('/sample.mp4');
    expect(fullBytes, media);
    expect(whole.headers.contentType!.mimeType, 'video/mp4');
    expect(whole.headers.value('Accept-Ranges'), 'bytes');
    expect(whole.headers.value('Cache-Control'), 'no-store');
    final (head, noBytes) = await read('/sample.mp4', method: 'HEAD');
    expect(head.contentLength, 64);
    expect(noBytes, isEmpty);
    for (final (range, start, end) in [
      ('bytes=8-15', 8, 15),
      ('bytes=60-', 60, 63),
      ('bytes=-4', 60, 63),
      ('bytes=60-999', 60, 63),
    ]) {
      final (response, bytes) = await read('/sample.mp4', range: range);
      expect(response.statusCode, 206);
      expect(response.headers.value('Content-Range'), 'bytes $start-$end/64');
      expect(response.contentLength, end - start + 1);
      expect(bytes, media.sublist(start, end + 1));
    }
    for (final range in [
      'bytes=64-',
      'bytes=8-2',
      'bytes=-0',
      'bytes=0-1,4-5',
    ]) {
      final (response, _) = await read('/sample.mp4', range: range);
      expect(response.statusCode, 416);
      expect(response.headers.value('Content-Range'), 'bytes */64');
    }
    final (empty, emptyBytes) = await read('/empty.bin');
    expect(empty.statusCode, 200);
    expect(emptyBytes, isEmpty);
    final (invalidEmpty, _) = await read('/empty.bin', range: 'bytes=0-');
    expect(invalidEmpty.statusCode, 416);
    final (outside, outsideBytes) = await read('/%2e%2e/private.txt');
    expect(outside.statusCode, anyOf(403, 404));
    expect(utf8.decode(outsideBytes), isNot(contains('outside-public-bundle')));
    final (missing, _) = await read('/missing.png');
    expect(missing.statusCode, 404);
    final (post, _) = await read('/', method: 'POST');
    expect(post.statusCode, 405);
  });
}
