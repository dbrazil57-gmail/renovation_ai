import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum PaintMarkKind { polygon, brush, erase, region }

enum LocalSurfaceKind { wall, floor, splashback }

enum LocalFinish { paint, squareTiles, rectangleTiles, brickTiles }

const localFinishLabels = {
  LocalFinish.paint: 'Paint colour',
  LocalFinish.squareTiles: 'Square tiles',
  LocalFinish.rectangleTiles: 'Large rectangular tiles',
  LocalFinish.brickTiles: 'Subway / brick tiles',
};

const localSurfaceLabels = {
  LocalSurfaceKind.wall: 'Wall',
  LocalSurfaceKind.floor: 'Floor',
  LocalSurfaceKind.splashback: 'Splashback',
};

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
  final LocalSurfaceKind kind;
  final LocalFinish finish;
  final double tileSize, tileAngle;
  final int groutRgb;
  PaintSurface({
    required this.name,
    this.rgb = 0xD7C7AC,
    this.coverage = .95,
    Iterable<PaintMark> marks = const [],
    this.kind = LocalSurfaceKind.wall,
    this.finish = LocalFinish.paint,
    this.tileSize = .16,
    this.tileAngle = 0,
    this.groutRgb = 0xDED8CE,
  }) : marks = List.unmodifiable(marks);
  PaintSurface copyWith({
    String? name,
    int? rgb,
    double? coverage,
    List<PaintMark>? marks,
    LocalSurfaceKind? kind,
    LocalFinish? finish,
    double? tileSize,
    double? tileAngle,
    int? groutRgb,
  }) => PaintSurface(
    name: name ?? this.name,
    rgb: rgb ?? this.rgb,
    coverage: coverage ?? this.coverage,
    marks: marks ?? this.marks,
    kind: kind ?? this.kind,
    finish: finish ?? this.finish,
    tileSize: tileSize ?? this.tileSize,
    tileAngle: tileAngle ?? this.tileAngle,
    groutRgb: groutRgb ?? this.groutRgb,
  );
  Map<String, dynamic> toMap() => {
    'name': name,
    'rgb': rgb,
    'coverage': coverage,
    'marks': marks.map((mark) => mark.toMap()).toList(),
    if (kind != LocalSurfaceKind.wall) 'surfaceKind': kind.name,
    if (finish != LocalFinish.paint) ...{
      'finish': finish.name,
      'tileSize': tileSize,
      'tileAngle': tileAngle,
      'groutRgb': groutRgb,
    },
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
      final kind = LocalSurfaceKind.values
          .where((v) => v.name == (item['surfaceKind'] ?? 'wall'))
          .firstOrNull;
      final finish = LocalFinish.values
          .where((v) => v.name == (item['finish'] ?? 'paint'))
          .firstOrNull;
      final tileSize = item['tileSize'] ?? .16,
          tileAngle = item['tileAngle'] ?? 0,
          grout = item['groutRgb'] ?? 0xDED8CE;
      if (kind == null ||
          finish == null ||
          tileSize is! num ||
          !tileSize.isFinite ||
          tileSize < .04 ||
          tileSize > .5 ||
          tileAngle is! num ||
          !tileAngle.isFinite ||
          tileAngle < 0 ||
          tileAngle > 180 ||
          grout is! int ||
          grout < 0 ||
          grout > 0xFFFFFF) {
        throw invalid;
      }
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
          kind: kind,
          finish: finish,
          tileSize: tileSize.toDouble(),
          tileAngle: tileAngle.toDouble(),
          groutRgb: grout,
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
        final finish = wall.finish == LocalFinish.paint
            ? 'paint $hex'
            : '${localFinishLabels[wall.finish]}, tile colour $hex, grout #${wall.groutRgb.toRadixString(16).padLeft(6, '0').toUpperCase()}, preview size ${(wall.tileSize * 100).round()}%, angle ${wall.tileAngle.round()} degrees';
        return '${wall.name} (${localSurfaceLabels[wall.kind]})$location: $finish';
      })
      .join('; ');
  final tiles = targets.any((surface) => surface.finish != LocalFinish.paint);
  return 'The selected image is a rough local ${tiles ? 'finish preview with paint/tile choices' : 'paint preview'}. Polish the selected finishes together in one photorealistic correction using these choices: $colours. '
      'Clean uneven boundaries, halos and small missed patches on those same selected surfaces. Integrate natural material texture, light and shadows with the approved design. '
      '${tiles ? 'Refine tile perspective, grout alignment and material realism within the selected floor/wall/splashback areas. The local pattern scale and angle are visual guidance, not measured installation dimensions. ' : ''}'
      'Keep all unselected surfaces, ceilings, trim, windows, doors, furniture, appliances, artwork, layout and camera viewpoint unchanged. A floor may change only if explicitly listed among the selected targets above. '
      'Do not redesign the approved concept, reintroduce old finishes, add decoration or recolour unrelated surfaces. Hex colours are approximate visual references, not exact paint or tile-product matches.';
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
  // Low-frequency light field prevents old floor patterns showing through a
  // new tile preview. Paint keeps its existing fine-grained wall shading.
  final tileLight =
      input.recipe.surfaces.any((s) => s.finish != LocalFinish.paint)
      ? img.gaussianBlur(
          img.copyResize(
            source,
            width: source.width >= source.height
                ? math.min(48, source.width)
                : null,
            height: source.height > source.width
                ? math.min(48, source.height)
                : null,
          ),
          radius: 2,
        )
      : null;
  final lightLuminance = tileLight == null
      ? null
      : Float64List.fromList([
          for (final p in tileLight) .2126 * p.r + .7152 * p.g + .0722 * p.b,
        ]);
  double luminanceAt(int x, int y, bool tiled) {
    if (!tiled) {
      final p = source.getPixel(x, y);
      return .2126 * p.r + .7152 * p.g + .0722 * p.b;
    }
    final light = tileLight!;
    final u = x * (light.width - 1) / math.max(1, source.width - 1);
    final v = y * (light.height - 1) / math.max(1, source.height - 1);
    final left = u.floor(), top = v.floor();
    double at(int xx, int yy) => lightLuminance![yy * light.width + xx];

    final right = math.min(left + 1, light.width - 1),
        bottom = math.min(top + 1, light.height - 1);
    final a = at(left, top) * (1 - (u - left)) + at(right, top) * (u - left);
    final b =
        at(left, bottom) * (1 - (u - left)) + at(right, bottom) * (u - left);
    return a * (1 - (v - top)) + b * (v - top);
  }

  var changed = 0;
  for (final surface in input.recipe.surfaces) {
    if (surface.coverage == 0 || surface.marks.isEmpty) continue;
    final tiled = surface.finish != LocalFinish.paint;
    final angle = surface.tileAngle * math.pi / 180;
    final cosine = math.cos(angle), sine = math.sin(angle);
    final tileWidth = surface.tileSize * math.min(source.width, source.height);
    final tileHeight =
        tileWidth * (surface.finish == LocalFinish.squareTiles ? 1 : .5);
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
      final alpha = pixel.r / 255;
      luminance += luminanceAt(pixel.x, pixel.y, tiled) * alpha;
      weight += alpha;
    }
    if (weight == 0) continue;
    final mean = math.max(20.0, luminance / weight);
    final red = (surface.rgb >> 16) & 255,
        green = (surface.rgb >> 8) & 255,
        blue = surface.rgb & 255;
    for (final pixel in mask) {
      if (pixel.r == 0) continue;
      final target = output.getPixel(pixel.x, pixel.y);
      final shade = (luminanceAt(pixel.x, pixel.y, tiled) / mean).clamp(
        .25,
        1.6,
      );
      final alpha = surface.coverage * pixel.r / 255;
      int mix(num previous, int colour) =>
          (previous * (1 - alpha) + (colour * shade).clamp(0, 255) * alpha)
              .round()
              .clamp(0, 255);
      var targetRgb = surface.rgb;
      if (tiled) {
        final dx = pixel.x - source.width / 2, dy = pixel.y - source.height / 2;
        var u = (dx * cosine + dy * sine) / tileWidth;
        final v = (-dx * sine + dy * cosine) / tileHeight;
        if (surface.finish == LocalFinish.brickTiles && v.floor().isOdd) {
          u += .5;
        }
        final fu = u - u.floor(), fv = v - v.floor();
        final edge = math.min(
          math.min(fu, 1 - fu) * tileWidth,
          math.min(fv, 1 - fv) * tileHeight,
        );
        if (edge < tileWidth * .018) targetRgb = surface.groutRgb;
      }
      final r = mix(target.r, tiled ? (targetRgb >> 16) & 255 : red),
          g = mix(target.g, tiled ? (targetRgb >> 8) & 255 : green),
          b = mix(target.b, tiled ? targetRgb & 255 : blue);
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
