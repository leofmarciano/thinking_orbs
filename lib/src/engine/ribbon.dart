// Ribbon: an undulating sash of parallel strands rides a great circle —
// the "composing" state. The tuned preset freezes the 3D tumble
// (spin 0), leaving the traveling undulation on a fixed band.
//
// The same painter also drives "breathing" (ring), via the `faceOn` flag:
// a face-on circle whose radius — not its out-of-plane offset — undulates,
// so it reads as a ring slowly morphing rather than a sash in orbit.

import 'dart:math' as math;

import 'core.dart';
import 'profiles.dart';

OrbFrame frameRibbon(double size, double t, ModeOpts o) {
  final cx = size / 2;
  final cy = size / 2;
  final bigR = (size / 2) * 0.78;
  // spin scales the 3D tumble; spin=0 freezes the band's orientation,
  // leaving only the traveling undulation
  final spin = o['spin'] ?? 1;
  const camTilt = 0.3;
  final pt = makeProj(t * 0.1 * spin, camTilt, cx, cy, 1);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);
  final faceOn = (o['faceOn'] ?? 0) != 0;

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

  // The band plane, precessing (frozen when spin=0). The projection squashes
  // the band's great circle vertically by cos(ta + camTilt); face-on sets
  // ta = -camTilt so that term is 1 and the band reads as a true circle
  // rather than ribbon's tilted ellipse.
  final ya = t * 0.24 * spin;
  final ta = faceOn ? -camTilt : 0.55 + 0.3 * math.sin(t * 0.18) * spin;
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

  // Radial lobes swell past R, so pull the base radius in by (most of) the
  // wobble amplitude. The silhouette then stays inside the frame however
  // far the deformation is pushed, while lobes keep getting deeper
  // relative to the mean radius.
  final wobAmp = 0.23 * (o['wobMul'] ?? 1);
  final baseR = faceOn ? bigR / (1 + 0.85 * wobAmp) : bigR;

  final baseLanes = o['lanes'] ?? 5;
  final segs = o['segs'] ?? 88;
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
      // A normal-direction wobble is cancelled by the re-normalisation
      // below: the point lands back on the sphere, so the silhouette is
      // pinned at R and the deformation can only ever pull dots inward.
      // Face-on instead modulates the in-plane RADIUS, so lobes genuinely
      // swell outward and pinch inward. Ribbon keeps the original
      // out-of-plane sash wobble.
      final radial = faceOn ? 1 + wob : 1.0;
      final off = faceOn ? laneOff : laneOff + wob;
      final x = ux * math.cos(a) + vx * math.sin(a) + nx * off;
      final y = uy * math.cos(a) + vy * math.sin(a) + ny * off;
      final z = uz * math.cos(a) + vz * math.sin(a) + nz * off;
      final l = math.sqrt(x * x + y * y + z * z);
      final rr = baseR * radial;
      final (px, py, zr) = pt((x / l) * rr, (y / l) * rr, (z / l) * rr);
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
  return finalizeFrame(dots, const [], o['rMin'] ?? 0.3);
}
