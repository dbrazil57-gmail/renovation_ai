import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'ai_types.dart';

List<Uint8List> prepareInternetPhotos(List<Uint8List> sources) =>
    sources.map((bytes) {
      var image = img.decodeImage(bytes);
      if (image == null) throw const FormatException('Unsupported photo');
      image = img.bakeOrientation(image);
      if (image.width > 2048 || image.height > 2048) {
        image = image.width >= image.height
            ? img.copyResize(image, width: 2048)
            : img.copyResize(image, height: 2048);
      }
      image.exif = img.ExifData();
      image.iccProfile = null;
      image.textData?.clear();
      return img.encodePng(image);
    }).toList();

Future<List<Uint8List>> internetPhotos(List<Uint8List> sources) async {
  if (sources.isEmpty ||
      sources.length > 7 ||
      sources.any((b) => b.isEmpty || b.length > 18 * 1024 * 1024) ||
      sources.fold<int>(0, (n, b) => n + b.length) > 36 * 1024 * 1024) {
    throw const AiFailure(
      'Use up to seven photos, 18 MB each and 36 MB combined.',
    );
  }
  try {
    return await compute(prepareInternetPhotos, sources);
  } catch (_) {
    throw const AiFailure(
      'A photo could not be prepared. No internet request was sent; the originals are unchanged.',
    );
  }
}
