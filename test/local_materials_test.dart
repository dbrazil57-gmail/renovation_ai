import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:renovision_ai/local_paint.dart';
import 'package:renovision_ai/tile_projection.dart';

void main() {
  test(
    'reviewed convex plane maps all four corners and rejects crossed geometry',
    () {
      const corners = [(.1, .1), (.9, .2), (.8, .9), (.2, .8)];
      final plane = TileProjection.fromCorners(corners)!;
      const uv = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
      for (var i = 0; i < 4; i++) {
        final mapped = plane.map(corners[i].$1, corners[i].$2);
        expect(mapped.$1, closeTo(uv[i].$1, 1e-6));
        expect(mapped.$2, closeTo(uv[i].$2, 1e-6));
      }
      expect(
        TileProjection.fromCorners([
          corners[0],
          corners[2],
          corners[1],
          corners[3],
        ]),
        isNull,
      );
    },
  );
  test('imported texture is bounded, immutable, metadata-free and portable with perspective', () {
    final texture = img.Image(width: 24, height: 24, numChannels: 4);
    for (final p in texture) {
      p
        ..r = (p.x % 4) * 35 + 80
        ..g = 150
        ..b = 110
        ..a = 255;
    }
    texture.exif.imageIfd.imageDescription = 'Private source sample';
    final sample = prepareTileTexture(img.encodePng(texture));
    final bytes = Uint8List.fromList(sample.$1);
    final surface = PaintSurface(
      name: 'Splashback',
      kind: LocalSurfaceKind.splashback,
      finish: LocalFinish.brickTiles,
      rgb: sample.$2,
      tileTexture: bytes,
      fitTilePlane: true,
      marks: [
        PaintMark(PaintMarkKind.polygon, const [
          PaintPoint(.1, .1),
          PaintPoint(.9, .2),
          PaintPoint(.8, .9),
          PaintPoint(.2, .8),
        ]),
      ],
    );
    bytes.fillRange(0, bytes.length, 0);
    expect(img.decodeImage(surface.tileTexture!), isNotNull);
    expect(
      img.decodeImage(surface.tileTexture!)!.exif.imageIfd.imageDescription,
      isNull,
    );
    expect(() => surface.tileTexture![0] = 0, throwsUnsupportedError);
    final recipe = LocalPaintRecipe(
      width: 100,
      height: 80,
      surfaces: [surface],
    );
    final restored = LocalPaintRecipe.fromMap(recipe.toMap());
    expect(restored.surfaces.single.fitTilePlane, true);
    expect(
      restored.surfaces.single.tileTexture,
      orderedEquals(surface.tileTexture!),
    );
    final source = img.Image(width: 100, height: 80, numChannels: 4);
    for (final p in source) {
      p
        ..r = 180
        ..g = 180
        ..b = 180
        ..a = 255;
    }
    final input = img.encodePng(source);
    final output = img.decodePng(
      renderLocalPaint(PaintRenderInput(input, restored)).bytes,
    )!;
    expect(output.getPixel(0, 0).r, 180);
    expect(output.getPixel(0, 0).a, 255);
    expect(
      renderLocalPaint(PaintRenderInput(input, restored)).changedPixels,
      greaterThan(0),
    );
    expect(
      paintRefinementPrompt(restored),
      contains('imported material sample'),
    );
  });
}
