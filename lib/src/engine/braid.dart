// Braid: three strands plait around the sphere — the "weaving" state.
// Each strand runs pole to pole on a helix, and a radial breathing term
// makes them trade places, reading as the over/under of a plait.

import 'dart:math' as math;

import 'core.dart';
import 'profiles.dart';

OrbFrame frameBraid(double size, double t, ModeOpts o) {
  final cx = size / 2;
  final cy = size / 2;
  final bigR = (size / 2) * 0.76;
  final pt = makeProj(t * 0.4, 0.3, cx, cy, 1);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <Dot>[];
  // count opts stay raw doubles so `i < n` iterates exactly like the JS
  // loop (ceil for non-integers) — do not .round() here
  final ghostN = o['ghostN'] ?? 150;
  for (var i = 0; i < ghostN; i++) {
    final d = fibDir(i, ghostN);
    final (px, py, z) = pt(d.$1 * bigR, d.$2 * bigR, d.$3 * bigR);
    final depth = (z / bigR + 1) / 2;
    dots.add(Dot(
        x: px, y: py, z: z, r: 0.8 * rs, white: 0.78, a: 0.1 + 0.22 * depth));
  }

  final strandN = o['strandN'] ?? 52;
  final turns = o['turns'] ?? 3;
  for (var s = 0; s < 3; s++) {
    final phase = (s / 3) * 2 * math.pi;
    for (var i = 0; i < strandN; i++) {
      // u walks pole to pole; the frac() drift slides the whole strand along
      final u = (frac(i / strandN + t * 0.045) * 2 - 1) * 0.96;
      final surf = math.sqrt(math.max(0.0, 1 - u * u));
      final endFade = math.min(1.0, (1 - u.abs()) / 0.1);
      final a = u * math.pi * turns + phase;
      // radial breathing: strands trade places — the over/under of a plait
      final weave =
          1 + 0.075 * math.sin(u * math.pi * turns * 2 + phase * 2 + t * 0.8);
      final rr = surf * bigR * weave;
      final (px, py, zr) =
          pt(math.cos(a) * rr, u * bigR * weave, math.sin(a) * rr);
      final depth = (zr / bigR + 1) / 2;
      dots.add(Dot(
        x: px,
        y: py,
        z: zr,
        r: ((o['rBase'] ?? 1.2) + (o['rDepth'] ?? 1.8) * depth) * rs,
        white: 0.55 - 0.45 * depth,
        a: endFade * (0.45 + 0.55 * depth),
      ));
    }
  }
  return finalizeFrame(dots, const [], o['rMin'] ?? 0.3);
}
