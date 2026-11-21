import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum PaintMarkKind { polygon, brush, erase, region }

/// Compact one-bit mask in normalized image coordinates; never image pixels.
class PaintRegion {
  final int width, height;
  final double sensitivity;
  final Uint8List bits;
  PaintRegion._(this.width, this.height, this.sensitivity, Uint8List bytes)
    : bits = Uint8List.fromList(bytes).asUnmodifiableView();
  factory PaintRegion({
    required int width,
    required int height,
    required Uint8List bits,
    double sensitivity = 28,
  }) => PaintRegion.fromMap({
    'width': width,
    'height': height,
    'bits': base64Encode(bits),
    'sensitivity': sensitivity,
  });
  factory PaintRegion.fromMap(Map value) {
    final w = value['width'],
        h = value['height'],
        encoded = value['rows'] ?? value['bits'],
        s = value['sensitivity'];
    const invalid = FormatException('Invalid wall selection.');
    if (w is! int ||
        h is! int ||
        w < 1 ||
        h < 1 ||
        w > 1024 ||
        h > 1024 ||
        encoded is! String ||
        encoded.length > 384 * 1024 ||
        s is! num ||
        !s.isFinite ||
        s < 8 ||
        s > 64) {
      throw invalid;
    }
    final packed = base64Decode(encoded);
    final bytes = Uint8List((w * h + 7) ~/ 8);
    if (value['rows'] != null) {
      if (value['bits'] != null || packed.length % 6 != 0) throw invalid;
      final rows = ByteData.sublistView(packed);
      var previousEnd = 0;
      for (var offset = 0; offset < packed.length; offset += 6) {
        final y = rows.getUint16(offset, Endian.little);
        final x = rows.getUint16(offset + 2, Endian.little);
        final count = rows.getUint16(offset + 4, Endian.little);
        final start = y * w + x;
        if (y >= h ||
            x >= w ||
            count == 0 ||
            count > w - x ||
            start < previousEnd) {
          throw invalid;
        }
        for (var i = start; i < start + count; i++) {
          bytes[i >> 3] |= 1 << (i & 7);
        }
        previousEnd = start + count;
      }
    } else {
      if (packed.length != bytes.length) throw invalid;
      bytes.setAll(0, packed);
    }
    final extra = (w * h) % 8;
    if (extra != 0) bytes[bytes.length - 1] &= (1 << extra) - 1;
    return PaintRegion._(w, h, s.toDouble(), bytes);
  }
  bool contains(int x, int y) {
    final index = y * width + x;
    return bits[index >> 3] & (1 << (index & 7)) != 0;
  }

  Map<String, dynamic> toMap() {
    final rows = BytesBuilder();
    for (var y = 0; y < height; y++) {
      var x = 0;
      while (x < width) {
        if (!contains(x, y)) {
          x++;
          continue;
        }
        final start = x;
        while (x < width && contains(x, y)) {
          x++;
        }
        final count = x - start;
        rows.add([
          y & 255,
          y >> 8,
          start & 255,
          start >> 8,
          count & 255,
          count >> 8,
        ]);
      }
    }
    return {
      'width': width,
      'height': height,
      'rows': base64Encode(rows.takeBytes()),
      'sensitivity': sensitivity,
    };
  }
}

class PaintPoint {
  final double x, y;
  const PaintPoint(this.x, this.y);
  List<double> toList() => [x, y];
}

class PaintMark {
  final PaintMarkKind kind;
  final List<PaintPoint> points;
  final double width;
  final PaintRegion? region;
  PaintMark(
    this.kind,
    Iterable<PaintPoint> points, {
    this.width = .035,
    this.region,
  }) : points = List.unmodifiable(points);
  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'width': width,
    'points': points.map((point) => point.toList()).toList(),
    if (region != null) 'region': region!.toMap(),
  };
}

class PaintSurface {
  final String name;
  final int rgb;
  final double coverage;
  final List<PaintMark> marks;
  PaintSurface({
    required this.name,
    this.rgb = 0xD7C7AC,
    this.coverage = .95,
    Iterable<PaintMark> marks = const [],
  }) : marks = List.unmodifiable(marks);
  PaintSurface copyWith({
    String? name,
    int? rgb,
    double? coverage,
    List<PaintMark>? marks,
  }) => PaintSurface(
    name: name ?? this.name,
    rgb: rgb ?? this.rgb,
    coverage: coverage ?? this.coverage,
    marks: marks ?? this.marks,
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'rgb': rgb,
    'coverage': coverage,
    'marks': marks.map((mark) => mark.toMap()).toList(),
  };
}

/// Geometry is relative to an immutable, oriented source image. Source IDs live
/// on the version / room draft, so portable copies can remap them normally.
class LocalPaintRecipe {
  final int width, height;
  final List<PaintSurface> surfaces;
  LocalPaintRecipe._(this.width, this.height, Iterable<PaintSurface> surfaces)
    : surfaces = List.unmodifiable(surfaces);
  factory LocalPaintRecipe({
    required int width,
    required int height,
    required List<PaintSurface> surfaces,
  }) => LocalPaintRecipe.fromMap({
    'width': width,
    'height': height,
    'surfaces': surfaces.map((s) => s.toMap()).toList(),
  });
  factory LocalPaintRecipe.empty(int width, int height) =>
      LocalPaintRecipe(width: width, height: height, surfaces: []);
  factory LocalPaintRecipe.fromMap(Map<dynamic, dynamic> value) {
    const invalid = FormatException('Invalid local paint settings.');
    final width = value['width'],
        height = value['height'],
        raw = value['surfaces'];
    if (width is! int ||
        height is! int ||
        width < 1 ||
        height < 1 ||
        width > 20000 ||
        height > 20000 ||
        raw is! List ||
        raw.length > 8) {
      throw invalid;
    }
    var totalPoints = 0;
    final surfaces = <PaintSurface>[];
    for (final item in raw) {
      if (item is! Map ||
          item['name'] is! String ||
          (item['name'] as String).length > 40 ||
          item['rgb'] is! int ||
          item['rgb'] < 0 ||
          item['rgb'] > 0xFFFFFF ||
          item['coverage'] is! num ||
          !(item['coverage'] as num).isFinite ||
          item['coverage'] < 0 ||
          item['coverage'] > 1 ||
          item['marks'] is! List ||
          (item['marks'] as List).length > 128) {
        throw invalid;
      }
      final marks = <PaintMark>[];
      for (final op in item['marks'] as List) {
        if (op is! Map) throw invalid;
        final kind = PaintMarkKind.values
            .where((kind) => kind.name == op['kind'])
            .firstOrNull;
        final points = op['points'], size = op['width'];
        if (kind == null ||
            size is! num ||
            !size.isFinite ||
            size < .002 ||
            size > .2 ||
            points is! List ||
            points.isEmpty ||
            points.length > 512) {
          throw invalid;
        }
        final parsed = <PaintPoint>[];
        for (final point in points) {
          if (point is! List ||
              point.length != 2 ||
              point.any((v) => v is! num || !v.isFinite || v < 0 || v > 1)) {
            throw invalid;
          }
          parsed.add(
            PaintPoint(
              (point[0] as num).toDouble(),
              (point[1] as num).toDouble(),
            ),
          );
        }
        totalPoints += parsed.length;
        if (totalPoints > 8192) throw invalid;
        PaintRegion? region;
        if (kind == PaintMarkKind.region) {
          if (op['region'] is! Map || parsed.length != 1) throw invalid;
          region = PaintRegion.fromMap(op['region'] as Map);
        } else if (op['region'] != null) {
          throw invalid;
        }
        marks.add(
          PaintMark(kind, parsed, width: size.toDouble(), region: region),
        );
      }
      surfaces.add(
        PaintSurface(
          name: item['name'],
          rgb: item['rgb'],
          coverage: (item['coverage'] as num).toDouble(),
          marks: marks,
        ),
      );
    }
    final recipe = LocalPaintRecipe._(width, height, surfaces);
    if (jsonEncode(recipe.toMap()).length > 384 * 1024) throw invalid;
    return recipe;
  }
  LocalPaintRecipe replaceSurface(int index, PaintSurface surface) =>
      LocalPaintRecipe(
        width: width,
        height: height,
        surfaces: [...surfaces]..[index] = surface,
      );
  Map<String, dynamic> toMap() => {
    'width': width,
    'height': height,
    'surfaces': surfaces.map((surface) => surface.toMap()).toList(),
  };
}

/// A reviewable correction request, not an enforced edit mask or paid request.
String paintRefinementPrompt(LocalPaintRecipe recipe) {
  final targets = recipe.surfaces.where(
    (wall) =>
        wall.coverage > 0 &&
        wall.marks.any((mark) => mark.kind != PaintMarkKind.erase),
  );
  final colours = targets
      .map((wall) {
        final hex =
            '#${wall.rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
        final seed = wall.marks
            .where((mark) => mark.kind == PaintMarkKind.region)
            .firstOrNull;
        final location = seed == null
            ? ''
            : ' near ${(seed.points.single.x * 100).round()}% across and ${(seed.points.single.y * 100).round()}% down the image';
        return '${wall.name}$location: $hex';
      })
      .join('; ');
  return 'The selected image is a rough local paint preview. Finish only the indicated wall paint as a photorealistic result, using these intended colours: $colours. '
      'Clean uneven paint boundaries, halos and small missed patches on those same wall surfaces. Preserve natural light, shadows and wall texture. '
      'Keep ceilings, trim, windows, doors, furniture, appliances, floors, artwork, the layout and camera viewpoint unchanged. '
      'Do not redesign, add decoration or recolour other surfaces. Hex colours are approximate visual references, not exact paint matches.';
}

class PaintPrepared {
  final Uint8List preview;
  final int width, height;
  PaintPrepared(this.preview, this.width, this.height);
}

PaintPrepared preparePaintImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('This image cannot be opened for paint.');
  }
  final oriented = img.bakeOrientation(decoded);
  if (oriented.width * oriented.height > 24000000) {
    throw const FormatException(
      'Use an image under 24 megapixels for local paint. Your original is unchanged.',
    );
  }
  final preview = math.max(oriented.width, oriented.height) <= 1000
      ? oriented
      : img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? 1000 : null,
          height: oriented.height > oriented.width ? 1000 : null,
        );
  preview.exif = img.ExifData();
  preview.iccProfile = null;
  preview.textData?.clear();
  return PaintPrepared(
    img.encodeJpg(preview, quality: 85),
    oriented.width,
    oriented.height,
  );
}

class PaintRenderInput {
  final Uint8List source;
  final LocalPaintRecipe recipe;
  final bool preview;
  PaintRenderInput(this.source, this.recipe, {this.preview = false});
}

class PaintRenderResult {
  final Uint8List bytes;
  final int changedPixels;
  PaintRenderResult(this.bytes, this.changedPixels);
}

/// Full output is lossless; pixels with zero mask coverage are never assigned.
/// Colour is an approximation retaining source luminance variation, not a
/// calibrated paint-brand / finish or lighting simulation.
PaintRenderResult renderLocalPaint(PaintRenderInput input) {
  final decoded = img.decodeImage(input.source);
  if (decoded == null) {
    throw const FormatException('This image cannot be painted.');
  }
  final source = img.bakeOrientation(decoded);
  if (source.width * source.height > 24000000 ||
      (!input.preview &&
          (source.width != input.recipe.width ||
              source.height != input.recipe.height))) {
    throw const FormatException(
      'The saved selection does not match this image.',
    );
  }
  // Expand indexed images before changing a colour; editing a palette entry
  // could otherwise recolour unselected pixels sharing that entry.
  final output = source.convert(numChannels: 4);
  var changed = 0;
  for (final surface in input.recipe.surfaces) {
    if (surface.coverage == 0 || surface.marks.isEmpty) continue;
    final mask = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 1,
    );
    for (final mark in surface.marks) {
      if (mark.kind == PaintMarkKind.region) {
        final region = mark.region!;
        final columns = List<int>.generate(
          source.width,
          (x) => source.width == 1
              ? 0
              : (x * (region.width - 1) / (source.width - 1)).round(),
        );
        for (var y = 0; y < source.height; y++) {
          final row = source.height == 1
              ? 0
              : (y * (region.height - 1) / (source.height - 1)).round();
          for (var x = 0; x < source.width; x++) {
            if (region.contains(columns[x], row)) {
              mask.setPixelRgba(x, y, 255, 255, 255, 255);
            }
          }
        }
        continue;
      }
      final value = mark.kind == PaintMarkKind.erase ? 0 : 255;
      final color = img.ColorRgb8(value, value, value);
      final points = mark.points
          .map(
            (p) => img.Point(
              (p.x * (source.width - 1)).round(),
              (p.y * (source.height - 1)).round(),
            ),
          )
          .toList();
      if (mark.kind == PaintMarkKind.polygon) {
        if (points.length >= 3) {
          img.fillPolygon(
            mask,
            vertices: points,
            color: color,
            blend: img.BlendMode.direct,
          );
        }
      } else {
        final radius = math.max(
          1,
          (mark.width * math.min(source.width, source.height) / 2).round(),
        );
        for (var i = 0; i < points.length; i++) {
          final p = points[i];
          img.fillCircle(
            mask,
            x: p.xi,
            y: p.yi,
            radius: radius,
            color: color,
            blend: img.BlendMode.direct,
          );
          if (i > 0) {
            img.drawLine(
              mask,
              x1: points[i - 1].xi,
              y1: points[i - 1].yi,
              x2: p.xi,
              y2: p.yi,
              color: color,
              thickness: radius * 2,
              blend: img.BlendMode.direct,
            );
          }
        }
      }
    }
    var luminance = 0.0, weight = 0.0;
    for (final pixel in mask) {
      if (pixel.r == 0) continue;
      final p = source.getPixel(pixel.x, pixel.y);
      final alpha = pixel.r / 255;
      luminance += (.2126 * p.r + .7152 * p.g + .0722 * p.b) * alpha;
      weight += alpha;
    }
    if (weight == 0) continue;
    final mean = math.max(20.0, luminance / weight);
    final red = (surface.rgb >> 16) & 255,
        green = (surface.rgb >> 8) & 255,
        blue = surface.rgb & 255;
    for (final pixel in mask) {
      if (pixel.r == 0) continue;
      final p = source.getPixel(pixel.x, pixel.y),
          target = output.getPixel(pixel.x, pixel.y);
      final shade = ((.2126 * p.r + .7152 * p.g + .0722 * p.b) / mean).clamp(
        .25,
        1.6,
      );
      final alpha = surface.coverage * pixel.r / 255;
      int mix(num previous, int colour) =>
          (previous * (1 - alpha) + (colour * shade).clamp(0, 255) * alpha)
              .round()
              .clamp(0, 255);
      final r = mix(target.r, red),
          g = mix(target.g, green),
          b = mix(target.b, blue);
      if (target.r != r || target.g != g || target.b != b) changed++;
      target
        ..r = r
        ..g = g
        ..b = b;
    }
  }
  output.exif = img.ExifData();
  output.iccProfile = null;
  output.textData?.clear();
  return PaintRenderResult(
    input.preview ? img.encodeJpg(output, quality: 85) : img.encodePng(output),
    changed,
  );
}
