import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

enum PaintMarkKind { polygon, brush, erase }

class PaintPoint {
  final double x, y;
  const PaintPoint(this.x, this.y);
  List<double> toList() => [x, y];
}

class PaintMark {
  final PaintMarkKind kind;
  final List<PaintPoint> points;
  final double width;
  PaintMark(this.kind, Iterable<PaintPoint> points, {this.width = .035})
    : points = List.unmodifiable(points);
  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'width': width,
    'points': points.map((point) => point.toList()).toList(),
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
  factory LocalPaintRecipe.empty(int width, int height) => LocalPaintRecipe(
    width: width,
    height: height,
    surfaces: [PaintSurface(name: 'Wall 1')],
  );
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
        raw.isEmpty ||
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
        marks.add(PaintMark(kind, parsed, width: size.toDouble()));
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
