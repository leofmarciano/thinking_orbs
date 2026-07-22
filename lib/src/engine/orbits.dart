// Orbits: particles on tilted orbits — the "working" state. No nucleus
// (the tuned preset runs coreless): just ghost paths and the particles
// doing the work.

import 'dart:math' as math;
import 'dart:ui';

import 'core.dart';
import 'profiles.dart';

void drawOrbits(
  Canvas canvas,
  double size,
  double t,
  bool dark,
  ModeOpts o, [
  Color? color,
]) {
  final cx = size / 2;
  final cy = size / 2;
  final r = (size / 2) * 0.82;
  final pt = makeProj(t * 0.12, 0.3, cx, cy, 1);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <Dot>[];
  final orbitN = (o['orbitN'] ?? 12).round();
  final ghostN = (o['ghostN'] ?? 40).round();
  final particles = (o['particles'] ?? 3).round();

  // orbits: each a tilted circle — a ghost path + running particles
  for (var orb = 0; orb < orbitN; orb++) {
    final h1 = hashD(orb.toDouble(), 1.7);
    final h2 = hashD(orb.toDouble(), 5.2);
    final h3 = hashD(orb.toDouble(), 8.9);
    final ro = r * (0.45 + 0.52 * h1);
    final th = h1 * 2 * math.pi;
    final phi = math.acos(2 * h2 - 1);
    // orbit plane basis (u, v ⟂ normal n)
    final nx = math.sin(phi) * math.cos(th);
    final ny = math.cos(phi);
    final nz = math.sin(phi) * math.sin(th);
    var ux = -ny;
    var uy = nx;
    const uz = 0.0;
    final ul = math.max(1e-6, math.sqrt(ux * ux + uy * uy));
    ux /= ul;
    uy /= ul;
    final vx = ny * uz - nz * uy;
    final vy = nz * ux - nx * uz;
    final vz = nx * uy - ny * ux;
    final speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1);

    // ghost path
    for (var k = 0; k < ghostN; k++) {
      final a = (k / ghostN) * 2 * math.pi;
      final (px, py, z) = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final depth = (z / ro + 1) / 2;
      dots.add(Dot(
        x: px,
        y: py,
        z: z,
        r: (o['ghostR'] ?? 0.9) * rs,
        white: 0.72,
        a: (o['ghostA'] ?? 0.5) * (0.4 + 0.6 * depth),
      ));
    }
    // the particles doing the work
    for (var m = 0; m < particles; m++) {
      final a = t * speed + (m / particles) * 2 * math.pi + h2 * 6;
      final (px, py, z) = pt(
        (ux * math.cos(a) + vx * math.sin(a)) * ro,
        (uy * math.cos(a) + vy * math.sin(a)) * ro,
        (uz * math.cos(a) + vz * math.sin(a)) * ro,
      );
      final depth = (z / ro + 1) / 2;
      dots.add(Dot(
        x: px,
        y: py,
        z: z,
        r: ((o['partR'] ?? 1.2) + (o['partRDepth'] ?? 1.6) * depth) * rs,
        white: 0.3 - 0.22 * depth,
      ));
    }
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3, color);
}
