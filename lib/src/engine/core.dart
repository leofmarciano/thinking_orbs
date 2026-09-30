// Shared primitives for the dotted 3D thought-orbs. Ported 1:1 from the
// original thinking-orbs (inkform / PlotterLab's HalftoneSphere lineage):
// honestly 3D — rotated, depth-shaded, z-sorted. Depth is carried by dot
// size and ink weight alone. Plain circle fills only: no filters, no
// shaders, so every mode renders identically on every platform.

import 'dart:math' as math;
import 'dart:ui';

/// A single mark: a projected, depth-shaded circle.
class Dot {
  Dot({
    required this.x,
    required this.y,
    required this.z,
    required this.r,
    required this.white,
    this.a,
  });

  /// Screen-space position after rotation and projection.
  final double x;
  final double y;

  /// Rotated depth — drives draw order and near/far shading.
  final double z;

  /// Rendered radius — mutable so [finalizeFrame] can clamp it in place.
  double r;

  /// Ink value: 0 = darkest ink on paper. Mirrored on dark themes.
  final double white;

  /// Optional extra opacity multiplier (ghost fades); null means opaque.
  final double? a;
}

/// A stroked edge between two projected points (the `connecting` web).
class Line {
  Line({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.white,
    this.a,
    required this.w,
  });

  /// Segment endpoints in screen space.
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  /// Ink value, same convention as [Dot.white].
  final double white;

  /// Optional extra opacity multiplier; null means opaque.
  final double? a;

  /// Stroke width in logical pixels.
  final double w;
}

/// One rendered instant: a complete, final set of draw instructions.
/// [dots] is already z-sorted into draw order and radius-clamped; [lines]
/// are drawn first. Nothing here needs further interpretation, which is
/// what makes a frame portable to any 2D renderer.
class OrbFrame {
  const OrbFrame({required this.dots, required this.lines});

  final List<Dot> dots;
  final List<Line> lines;
}

/// Projected point: screen x, screen y and rotated depth z.
typedef Projected = (double, double, double);

/// A 3D→2D projection closure from [makeProj]: maps a model-space point
/// to its screen-space [Projected].
typedef Projector = Projected Function(double x, double y, double z);

double lerp(double a, double b, double f) {
  return a + (b - a) * f;
}

double frac(double x) {
  return x - x.floorToDouble();
}

/// Value noise on a 2D lattice — smooth, deterministic, cheap.
double vnoise(double x, double y) {
  final xi = x.floorToDouble();
  final yi = y.floorToDouble();
  var fx = x - xi;
  var fy = y - yi;
  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  final a = hashD(xi, yi);
  final b = hashD(xi + 1, yi);
  final c = hashD(xi, yi + 1);
  final d = hashD(xi + 1, yi + 1);
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
}

/// Deterministic hash in [0, 1).
double hashD(double a, double b) {
  final h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

/// Stable directions on a unit sphere (Fibonacci lattice). `n` stays a
/// raw double: mode loops pass their un-rounded count, as upstream does.
(double, double, double) fibDir(int i, double n) {
  final golden = math.pi * (3 - math.sqrt(5));
  final y = 1 - (2 * (i + 0.5)) / n;
  final rad = math.sqrt(1 - y * y);
  final a = i * golden;
  return (rad * math.cos(a), y, rad * math.sin(a));
}

/// Shortest signed angular distance, wrapped to (-pi, pi].
double angleDelta(double a, double b) {
  return math.atan2(math.sin(a - b), math.cos(a - b));
}

/// Shared spin + tilt + orthographic projection.
Projector makeProj(
    double yaw, double tilt, double cx, double cy, double scale) {
  final st = math.sin(tilt);
  final ct = math.cos(tilt);
  final sy = math.sin(yaw);
  final cyw = math.cos(yaw);
  return (x, y, z) {
    final x1 = x * cyw + z * sy;
    final z1 = -x * sy + z * cyw;
    final y1 = y * ct - z1 * st;
    final z2 = y * st + z1 * ct;
    return (cx + x1 * scale, cy - y1 * scale, z2);
  };
}

/// Painter: renders finalized dots far→near, grayscale or custom-color.
/// On dark substrates the monochrome ink value is mirrored (1 - white) so
/// near dots read bright. Custom colors carry the same depth through
/// opacity. Culling, radius-clamping and z-sorting already happened in
/// [finalizeFrame] — this pass draws the list verbatim.
void paintDots(
  Canvas canvas,
  List<Dot> dots,
  bool dark, [
  Color? color,
]) {
  final paint = Paint()..style = PaintingStyle.fill;
  for (final d in dots) {
    final alpha = d.a ?? 1;
    final w = d.white.clamp(0.0, 1.0);
    if (color != null) {
      // Use the original ink strength as opacity so the supplied hue keeps
      // the same near/far depth language on both light and dark substrates.
      // `alpha` is retained for modes that intentionally fade ghost dots.
      // ignore: deprecated_member_use
      final colorAlpha = color.alpha;
      final tintedAlpha = (colorAlpha * alpha * (1 - w)).round().clamp(0, 255);
      paint.color = color.withAlpha(tintedAlpha);
    } else {
      final g = ((dark ? 1 - w : w) * 255).round();
      paint.color = Color.fromRGBO(g, g, g, alpha.clamp(0.0, 1.0));
    }
    canvas.drawCircle(Offset(d.x, d.y), d.r, paint);
  }
}

/// Stroke pass for edge-based modes. Runs before [paintDots] so nodes sit
/// on top. Custom colors tint lines by ink strength (1 - white), same as
/// dots.
void paintLines(
  Canvas canvas,
  List<Line> lines,
  bool dark, [
  Color? color,
]) {
  final paint = Paint()..style = PaintingStyle.stroke;
  for (final l in lines) {
    final alpha = l.a ?? 1;
    final w = l.white.clamp(0.0, 1.0);
    if (color != null) {
      // ignore: deprecated_member_use
      final colorAlpha = color.alpha;
      final tintedAlpha = (colorAlpha * alpha * (1 - w)).round().clamp(0, 255);
      paint.color = color.withAlpha(tintedAlpha);
    } else {
      final g = ((dark ? 1 - w : w) * 255).round();
      paint.color = Color.fromRGBO(g, g, g, alpha.clamp(0.0, 1.0));
    }
    paint.strokeWidth = l.w;
    canvas.drawLine(Offset(l.x1, l.y1), Offset(l.x2, l.y2), paint);
  }
}

/// Turn raw mode output into a finished frame: drop invisible marks, clamp
/// radii to the mode's floor, and z-sort far→near into draw order.
///
/// This runs in the GEOMETRY step, not the painter, so a frame is a
/// complete set of draw instructions: every value is final and the array
/// order is the order to draw in. That is what lets the golden-vector
/// parity tests compare numbers instead of pixels.
OrbFrame finalizeFrame(List<Dot> dots, List<Line> lines, [double rMin = 0.3]) {
  final visible = <Dot>[];
  for (final d in dots) {
    if ((d.a ?? 1) < 0.02) continue;
    d.r = math.max(rMin, d.r);
    visible.add(d);
  }
  // Dart's List.sort is not stable; sorting indices with an insertion-order
  // tie-break reproduces JS's stable sort exactly (e.g. morph's all-z=0
  // dots keep their push order).
  final order = List<int>.generate(visible.length, (i) => i)
    ..sort((a, b) {
      final c = visible[a].z.compareTo(visible[b].z);
      return c != 0 ? c : a.compareTo(b);
    });
  return OrbFrame(
    dots: [for (final i in order) visible[i]],
    lines: lines.where((l) => (l.a ?? 1) >= 0.02).toList(),
  );
}

/// Paint a finished frame. Lines first, so nodes sit on top of their edges.
void paintFrame(Canvas canvas, OrbFrame frame, bool dark, [Color? color]) {
  if (frame.lines.isNotEmpty) paintLines(canvas, frame.lines, dark, color);
  paintDots(canvas, frame.dots, dark, color);
}

/// Dot radii were tuned for a 300pt frame; sub-linear scaling keeps small
/// spinners legible. Lower pow = radii shrink less with size.
double radiusScale(double size, double pow) {
  return math.pow(size / 300, pow).toDouble();
}
