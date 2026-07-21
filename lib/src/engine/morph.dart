// Morph: a dotted outline cycling circle → triangle → square → circle —
// the "shaping" state. Each shape is a continuous closed path
// parameterised by arc length (top-centre start, clockwise). Every
// frame the engine blends the two neighbouring paths, then lays the
// dots EVENLY along the blended outline — spacing stays uniform at
// every instant of the morph, holds and transitions alike. Plain
// circle fills only, fully cross-platform.

import 'dart:math' as math;
import 'dart:ui';

import 'core.dart';
import 'profiles.dart';

typedef _Path = (double, double) Function(double f);

double _smoothE(double x) {
  return x * x * (3 - 2 * x);
}

_Path _polyPath(List<(double, double)> verts) {
  final v = verts.length;
  final lens = <double>[];
  var total = 0.0;
  for (var i = 0; i < v; i++) {
    final a = verts[i];
    final b = verts[(i + 1) % v];
    final l = math.sqrt(math.pow(b.$1 - a.$1, 2) + math.pow(b.$2 - a.$2, 2));
    lens.add(l);
    total += l;
  }
  return (f) {
    var target = f * total;
    var i = 0;
    while (target > lens[i] && i < v - 1) {
      target -= lens[i];
      i++;
    }
    final a = verts[i];
    final b = verts[(i + 1) % v];
    final ff = lens[i] != 0 ? math.min(1.0, target / lens[i]) : 0.0;
    return (a.$1 + (b.$1 - a.$1) * ff, a.$2 + (b.$2 - a.$2) * ff);
  };
}

(double, double) _circle(double f) {
  final a = -math.pi / 2 + f * 2 * math.pi;
  return (math.cos(a) * 0.24, math.sin(a) * 0.24);
}

final _Path _triangle = _polyPath([
  (0.0, -0.26),
  (0.24, 0.16),
  (-0.24, 0.16),
]);
// 5-vertex walk so the path STARTS at top-centre like the other shapes
final _Path _square = _polyPath([
  (0, -0.2),
  (0.2, -0.2),
  (0.2, 0.2),
  (-0.2, 0.2),
  (-0.2, -0.2),
]);
final List<_Path> _cycle = [_circle, _triangle, _square];

// low floor keeps sparse outlines possible while never degenerating
int _morphN(double d) {
  return math.max(6, (34 * d).round());
}

const double _hold = 1.4;
const double _morphDur = 0.9;
const double _seg = _hold + _morphDur;

void drawMorph(Canvas canvas, double size, double t, bool dark, ModeOpts o) {
  final kCount = _cycle.length;
  final tc = t % (_seg * kCount);
  final k = (tc / _seg).floor();
  final local = tc - k * _seg;
  final m = local > _hold ? _smoothE((local - _hold) / _morphDur) : 0.0;
  final sprd = o['spread'] ?? 1;

  // blend the two shape PATHS at m, then measure the blended outline
  final pA = _cycle[k];
  final pB = _cycle[(k + 1) % kCount];
  const bigM = 160;
  final pts = <(double, double)>[];
  for (var i = 0; i < bigM; i++) {
    final f = i / bigM;
    final a = pA(f);
    final b = pB(f);
    pts.add(((a.$1 + (b.$1 - a.$1) * m) * sprd, (a.$2 + (b.$2 - a.$2) * m) * sprd));
  }
  final lens = <double>[];
  var total = 0.0;
  for (var i = 0; i < bigM; i++) {
    final a = pts[i];
    final b = pts[(i + 1) % bigM];
    final l = math.sqrt(math.pow(b.$1 - a.$1, 2) + math.pow(b.$2 - a.$2, 2));
    lens.add(l);
    total += l;
  }

  // dot radius depends ONLY on rDot (the size knob); the count sets the
  // gaps. Formed shapes breathe a little (uniform pulse).
  final n = _morphN(o['iconD'] ?? 1);
  final re = (o['rDot'] ?? 0.021) * 1.35 * sprd;
  final pulse = 1 + 0.02 * math.sin(local * 3.1);

  final dots = <Dot>[];
  final c2 = size / 2;
  var seg = 0;
  var acc = 0.0;
  for (var k2 = 0; k2 < n; k2++) {
    final target = (k2 / n) * total;
    while (acc + lens[seg] < target && seg < bigM - 1) {
      acc += lens[seg];
      seg++;
    }
    final a = pts[seg];
    final b = pts[(seg + 1) % bigM];
    final f = lens[seg] != 0 ? math.min(1.0, (target - acc) / lens[seg]) : 0.0;
    final x = (a.$1 + (b.$1 - a.$1) * f) * pulse;
    final y = (a.$2 + (b.$2 - a.$2) * f) * pulse;
    dots.add(Dot(
      x: c2 + x * size,
      y: c2 + y * size,
      z: 0,
      r: math.max(0.35, re * size),
      white: 0.1,
    ));
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3);
}
