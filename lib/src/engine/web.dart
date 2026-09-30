// Web: a constellation wires itself — the "connecting" state. Nodes drift
// on the sphere under slow value noise; any pair closer than `thr` grows an
// edge, and bright packets run along randomly re-picked node pairs.

import 'dart:math' as math;

import 'core.dart';
import 'profiles.dart';

OrbFrame frameWeb(double size, double t, ModeOpts o) {
  final cx = size / 2;
  final cy = size / 2;
  final bigR = (size / 2) * 0.8 * (o['spread'] ?? 1);
  // note the projector carries the radius as its scale, so node vectors
  // stay unit-length and distances below are in unit-sphere space
  final pt = makeProj(t * 0.12, 0.32, cx, cy, bigR);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);

  // count opts stay raw doubles so `i < n` iterates exactly like the JS
  // loop (ceil for non-integers) — do not .round() here
  final nodeN = o['nodeN'] ?? 30;
  final thr = o['thr'] ?? 0.72;
  final nodeR = o['nodeR'] ?? 1.4;
  final nodeRDepth = o['nodeRDepth'] ?? 1.8;

  // nodes: fib lattice + slow noise wander, renormalised to the surface
  final nodes = <(double, double, double)>[];
  for (var i = 0; i < nodeN; i++) {
    final d = fibDir(i, nodeN);
    final x = d.$1 + 0.3 * (vnoise(0.31 * i + 9, t * 0.24) - 0.5) * 2;
    final y = d.$2 + 0.3 * (vnoise(0.53 * i + 27, t * 0.21) - 0.5) * 2;
    final z = d.$3 + 0.3 * (vnoise(0.77 * i + 55, t * 0.27) - 0.5) * 2;
    final l = math.sqrt(x * x + y * y + z * z);
    nodes.add((x / l, y / l, z / l));
  }

  final lines = <Line>[];
  final dots = <Dot>[];

  // edges between close neighbours, alpha by proximity + depth
  for (var i = 0; i < nodeN; i++) {
    for (var j = i + 1; j < nodeN; j++) {
      final dx = nodes[i].$1 - nodes[j].$1;
      final dy = nodes[i].$2 - nodes[j].$2;
      final dz = nodes[i].$3 - nodes[j].$3;
      final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
      if (dist >= thr) continue;
      final (x1, y1, z1) = pt(nodes[i].$1, nodes[i].$2, nodes[i].$3);
      final (x2, y2, z2) = pt(nodes[j].$1, nodes[j].$2, nodes[j].$3);
      final depth = ((z1 + z2) / 2 + 1) / 2;
      lines.add(Line(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        white: 0.42,
        a: (1 - dist / thr) * (0.3 + 0.55 * depth),
        w: math.max(0.6, (o['lineW'] ?? 0.8) * rs),
      ));
    }
  }

  for (var i = 0; i < nodeN; i++) {
    final (px, py, z) = pt(nodes[i].$1, nodes[i].$2, nodes[i].$3);
    final depth = (z + 1) / 2;
    final pulse = 1 + 0.25 * math.sin(t * 1.4 + 2.7 * i);
    dots.add(Dot(
      x: px,
      y: py,
      z: z,
      r: (nodeR + nodeRDepth * depth) * pulse * rs,
      white: 0.55 - 0.45 * depth,
    ));
  }

  // signals: bright packets running between paired nodes
  final signals = o['signals'] ?? 5;
  for (var s = 0; s < signals; s++) {
    final seg = (t * 0.55 + 7.31 * s).floorToDouble();
    final a = (hashD(seg, 3.1 * s + 1.7) * nodeN).floor();
    final b = (hashD(seg, 5.7 * s + 4.2) * nodeN).floor();
    // a/b are in range for any nodeN >= 1; nodeN <= 0 is outside
    // upstream's domain (it crashes there) — skip rather than index
    // an empty/sparse node list
    if (a == b || a < 0 || b < 0 || a >= nodes.length || b >= nodes.length) {
      continue;
    }
    final f = frac(t * 0.55 + 7.31 * s);
    final x = lerp(nodes[a].$1, nodes[b].$1, f);
    final y = lerp(nodes[a].$2, nodes[b].$2, f);
    final z = lerp(nodes[a].$3, nodes[b].$3, f);
    final l = math.max(1e-6, math.sqrt(x * x + y * y + z * z));
    final (px, py, zr) = pt(x / l, y / l, z / l);
    final depth = (zr + 1) / 2;
    dots.add(Dot(
      x: px,
      y: py,
      z: zr,
      r: (nodeR * 1.5 + nodeRDepth * depth) * rs,
      white: 0.05,
      a: 0.5 + 0.5 * depth,
    ));
  }

  return finalizeFrame(dots, lines, o['rMin'] ?? 0.3);
}
