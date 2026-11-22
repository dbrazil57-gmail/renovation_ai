import 'dart:math' as math;

/// Homography from a reviewed four-corner image plane to tile coordinates.
/// This is visual perspective guidance, not measured or inferred room geometry.
class TileProjection {
  final List<double> h;
  TileProjection._(this.h);
  static TileProjection? fromCorners(List<(double, double)> points) {
    if (points.length != 4) return null;
    double? sign;
    for (var i = 0; i < 4; i++) {
      final a = points[i], b = points[(i + 1) % 4], c = points[(i + 2) % 4];
      final cross =
          (b.$1 - a.$1) * (c.$2 - b.$2) - (b.$2 - a.$2) * (c.$1 - b.$1);
      if (cross.abs() < 1e-9 || sign != null && cross * sign < 0) return null;
      sign = cross;
    }
    const uv = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
    final rows = <List<double>>[];
    for (var i = 0; i < 4; i++) {
      final (x, y) = points[i];
      final (u, v) = uv[i];
      rows.add([x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
      rows.add([0, 0, 0, x, y, 1, -v * x, -v * y, v]);
    }
    for (var col = 0; col < 8; col++) {
      var pivot = col;
      for (var r = col + 1; r < 8; r++) {
        if (rows[r][col].abs() > rows[pivot][col].abs()) pivot = r;
      }
      if (rows[pivot][col].abs() < 1e-10) return null;
      final swap = rows[col];
      rows[col] = rows[pivot];
      rows[pivot] = swap;
      final scale = rows[col][col];
      for (var j = col; j <= 8; j++) {
        rows[col][j] /= scale;
      }
      for (var r = 0; r < 8; r++) {
        if (r == col) continue;
        final factor = rows[r][col];
        for (var j = col; j <= 8; j++) {
          rows[r][j] -= factor * rows[col][j];
        }
      }
    }
    return TileProjection._([for (var i = 0; i < 8; i++) rows[i][8]]);
  }

  (double, double) map(double x, double y) {
    final denominator = h[6] * x + h[7] * y + 1;
    if (denominator.abs() < 1e-10) return (0, 0);
    return (
      (h[0] * x + h[1] * y + h[2]) / denominator,
      (h[3] * x + h[4] * y + h[5]) / denominator,
    );
  }

  static double edge(
    (double, double) a,
    (double, double) b,
    double width,
    double height,
  ) => math.sqrt(
    math.pow((b.$1 - a.$1) * width, 2) + math.pow((b.$2 - a.$2) * height, 2),
  );
}
