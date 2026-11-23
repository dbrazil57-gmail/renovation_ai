import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'local_paint.dart';

class WallSelectionInput {
  final Uint8List image;
  final PaintPoint seed;
  final double sensitivity;
  WallSelectionInput(this.image, this.seed, {this.sensitivity = 28});
}

class WallSelectionResult {
  final PaintRegion region;
  final int pixels;
  WallSelectionResult(this.region, this.pixels);
}

/// Explicit directional expansion of a reviewed mask. The original is immutable;
/// the editor records this as an undoable draft change, not a source-image edit.
PaintRegion extendWallSelectionEdge(
  PaintRegion region, {
  int left = 1,
  int right = 1,
  int top = 1,
  int bottom = 1,
}) {
  if ([left, right, top, bottom].any((v) => v < 0 || v > 32)) {
    throw ArgumentError('Use an edge extension from 0 to 32 pixels.');
  }
  // Separable moving windows stay linear in mask size, even for wider edges.
  final horizontal = Uint8List(region.bits.length),
      bits = Uint8List(region.bits.length);
  void put(Uint8List bytes, int x, int y) {
    final index = y * region.width + x;
    bytes[index >> 3] |= 1 << (index & 7);
  }

  bool at(Uint8List bytes, int x, int y) {
    final index = y * region.width + x;
    return bytes[index >> 3] & (1 << (index & 7)) != 0;
  }

  for (var y = 0; y < region.height; y++) {
    var count = 0;
    for (var x = 0; x <= left && x < region.width; x++) {
      if (region.contains(x, y)) count++;
    }
    for (var x = 0; x < region.width; x++) {
      if (count > 0) put(horizontal, x, y);
      if (x - right >= 0 && region.contains(x - right, y)) count--;
      if (x + left + 1 < region.width && region.contains(x + left + 1, y)) {
        count++;
      }
    }
  }
  for (var x = 0; x < region.width; x++) {
    var count = 0;
    for (var y = 0; y <= top && y < region.height; y++) {
      if (at(horizontal, x, y)) count++;
    }
    for (var y = 0; y < region.height; y++) {
      if (count > 0) put(bits, x, y);
      if (y - bottom >= 0 && at(horizontal, x, y - bottom)) count--;
      if (y + top + 1 < region.height && at(horizontal, x, y + top + 1)) {
        count++;
      }
    }
  }
  return PaintRegion(
    width: region.width,
    height: region.height,
    bits: bits,
    sensitivity: region.sensitivity,
  );
}

/// Connected colour/edge selection, not semantic wall recognition. The user
/// checks the visible boundary; similar adjacent surfaces can need adjustment.
WallSelectionResult selectWallRegion(WallSelectionInput input) {
  if (!input.seed.x.isFinite ||
      !input.seed.y.isFinite ||
      input.seed.x < 0 ||
      input.seed.x > 1 ||
      input.seed.y < 0 ||
      input.seed.y > 1 ||
      !input.sensitivity.isFinite ||
      input.sensitivity < 8 ||
      input.sensitivity > 64) {
    throw const FormatException('Choose a point inside the image.');
  }
  final decoded = img.decodeImage(input.image);
  if (decoded == null) {
    throw const FormatException('The wall image could not be read.');
  }
  final oriented = img.bakeOrientation(decoded);
  if (oriented.width * oriented.height > 24000000) {
    throw const FormatException('Use an image under 24 megapixels.');
  }
  final image = math.max(oriented.width, oriented.height) <= 1000
      ? oriented
      : img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1000 : null,
          height: oriented.height > oriented.width ? 1000 : null,
        );
  final width = image.width, height = image.height, length = width * height;
  final luminance = Float32List(length),
      redChroma = Float32List(length),
      blueChroma = Float32List(length);
  for (final p in image) {
    final i = p.y * width + p.x;
    luminance[i] = .2126 * p.r + .7152 * p.g + .0722 * p.b;
    redChroma[i] = p.r - luminance[i];
    blueChroma[i] = p.b - luminance[i];
  }
  final sx = (input.seed.x * (width - 1)).round(),
      sy = (input.seed.y * (height - 1)).round();
  final seed = sy * width + sx;
  // A dilated edge barrier closes small gaps in seams and thin picture frames.
  // Seed-colour matching alone can leak into similarly coloured bedding/trim.
  final barrier = Uint8List(length);
  for (var y = 1; y < height - 1; y++) {
    for (var x = 1; x < width - 1; x++) {
      final i = y * width + x;
      double edge(int a, int b) =>
          (luminance[a] - luminance[b]).abs() +
          .65 * (redChroma[a] - redChroma[b]).abs() +
          .65 * (blueChroma[a] - blueChroma[b]).abs();
      if (math.max(edge(i - 1, i + 1), edge(i - width, i + width)) <
          input.sensitivity * .4) {
        continue;
      }
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final ex = x + dx, ey = y + dy;
          if (ex >= 0 && ex < width && ey >= 0 && ey < height) {
            barrier[ey * width + ex] = 1;
          }
        }
      }
    }
  }
  if (barrier[seed] != 0) {
    throw const FormatException(
      'Tap a clear part of the wall, away from edges and objects.',
    );
  }
  final queue = Int32List(length),
      visited = Uint8List(length),
      bits = Uint8List((length + 7) ~/ 8);
  var head = 0, tail = 1, pixels = 0;
  queue[0] = seed;
  visited[seed] = 1;
  final tolerance = input.sensitivity;
  bool similar(int i, int from) =>
      (luminance[i] - luminance[seed]).abs() <= tolerance * 1.9 &&
      (redChroma[i] - redChroma[seed]).abs() <= tolerance &&
      (blueChroma[i] - blueChroma[seed]).abs() <= tolerance &&
      (luminance[i] - luminance[from]).abs() <= tolerance * .85 &&
      (redChroma[i] - redChroma[from]).abs() <= tolerance * .8 &&
      (blueChroma[i] - blueChroma[from]).abs() <= tolerance * .8;
  while (head < tail) {
    final i = queue[head++];
    bits[i >> 3] |= 1 << (i & 7);
    pixels++;
    final x = i % width, y = i ~/ width;
    for (final next in [
      if (x > 0) i - 1,
      if (x < width - 1) i + 1,
      if (y > 0) i - width,
      if (y < height - 1) i + width,
    ]) {
      if (visited[next] != 0 || barrier[next] != 0 || !similar(next, i)) {
        continue;
      }
      visited[next] = 1;
      queue[tail++] = next;
    }
  }
  if (pixels < math.min(12, length)) {
    throw const FormatException(
      'Tap a clearer part of the wall, or increase sensitivity.',
    );
  }
  return WallSelectionResult(
    PaintRegion(
      width: width,
      height: height,
      bits: bits,
      sensitivity: input.sensitivity,
    ),
    pixels,
  );
}
