// Ribbon: an undulating sash of parallel strands rides a great circle —
// the "composing" state. The tuned preset freezes the 3D tumble
// (spin 0), leaving the traveling undulation on a fixed band.

import 'dart:math' as math;
import 'dart:ui';

import 'core.dart';
import 'profiles.dart';

void drawRibbon(
  Canvas canvas,
  double size,
  double t,
  bool dark,
  ModeOpts o, [
  Color? color,
]) {
  final cx = size / 2;
  final cy = size / 2;
  final bigR = (size / 2) * 0.78;
  // spin scales the 3D tumble; spin=0 freezes the band's orientation,
  // leaving only the traveling undulation
  final spin = o['spin'] ?? 1;
  final pt = makeProj(t * 0.1 * spin, 0.3, cx, cy, 1);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <Dot>[];
  final ghostN = (o['ghostN'] ?? 150).round();
  for (var i = 0; i < ghostN; i++) {
    final d = fibDir(i, ghostN);
    final (px, py, z) = pt(d.$1 * bigR, d.$2 * bigR, d.$3 * bigR);
    final depth = (z / bigR + 1) / 2;
    dots.add(Dot(
        x: px, y: py, z: z, r: 0.8 * rs, white: 0.78, a: 0.1 + 0.22 * depth));
  }

  // the band plane, precessing (frozen when spin=0)
  final ya = t * 0.24 * spin;
  final ta = 0.55 + 0.3 * math.sin(t * 0.18) * spin;
  final ux = math.cos(ya);
  const uy = 0.0;
  final uz = math.sin(ya);
  final vx = -uz * math.sin(ta);
  final vy = math.cos(ta);
  final vz = ux * math.sin(ta);
  // plane normal n = u × v
  final nx = uy * vz - uz * vy;
  final ny = uz * vx - ux * vz;
  final nz = ux * vy - uy * vx;

  final baseLanes = o['lanes'] ?? 5;
  final segs = (o['segs'] ?? 88).round();
  final lanes = math.max(1, (baseLanes * (o['bandMul'] ?? 1)).round());
  for (var w = 0; w < lanes; w++) {
    final laneOff = (w - (lanes - 1) / 2) * 0.075;
    final edge = (w - (lanes - 1) / 2).abs() / math.max(1.0, (lanes - 1) / 2);
    for (var k = 0; k < segs; k++) {
      final a = (k / segs) * 2 * math.pi;
      // the undulation: two traveling waves along the band; wobMul
      // scales the deformation — 0 is a clean band
      final wob = (0.16 * math.sin(a * 3 - t * 1.7 + w * 0.22) +
              0.07 * math.sin(a * 5 + t * 1.1)) *
          (o['wobMul'] ?? 1);
      final off = laneOff + wob;
      final x = ux * math.cos(a) + vx * math.sin(a) + nx * off;
      final y = uy * math.cos(a) + vy * math.sin(a) + ny * off;
      final z = uz * math.cos(a) + vz * math.sin(a) + nz * off;
      final l = math.sqrt(x * x + y * y + z * z);
      final (px, py, zr) = pt((x / l) * bigR, (y / l) * bigR, (z / l) * bigR);
      final depth = (zr / bigR + 1) / 2;
      dots.add(Dot(
        x: px,
        y: py,
        z: zr,
        r: ((o['rBase'] ?? 1.1) + (o['rDepth'] ?? 1.7) * depth) *
            (1 - 0.25 * edge) *
            rs,
        white: 0.52 - 0.44 * depth + 0.18 * edge,
        a: 0.4 + 0.6 * depth,
      ));
    }
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3, color);
}
