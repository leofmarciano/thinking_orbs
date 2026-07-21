// The sphere-lattice modes: globe (searching), rubik (solving) and
// wave (listening). All draw a lat/long dot field with mode-specific
// motion, then hand off to the shared z-sorted painter.

import 'dart:math' as math;
import 'dart:ui';

import 'core.dart';
import 'profiles.dart';

// --- the shared solver heartbeat (rubik) ------------------------------
// Rapid eased moves scramble, then replay in reverse (palindrome) so
// everything clicks back to solved, rests, repeats.

class _Move {
  _Move({required this.axis, required this.lo, required this.hi, required this.ang});

  final int axis; // 0 | 1 | 2
  final double lo;
  final double hi;
  final double ang;
}

class _SolveCycle {
  _SolveCycle(this.amount, this.active);

  final List<double> amount;
  final int active;
}

_SolveCycle _solveCycle(double time, int count, double slotDur, double rest) {
  final cyc = 2 * count * slotDur + rest;
  final tc = time % cyc;
  final amount = List<double>.filled(count, 0);
  var active = -1;
  if (tc < 2 * count * slotDur) {
    final slot = (tc / slotDur).floor();
    final p = (tc - slot * slotDur) / slotDur;
    final cl = math.min(1.0, p / 0.7);
    final ep = 1 - math.pow(1 - cl, 3).toDouble(); // machine ease-out
    if (slot < count) {
      for (var i = 0; i < slot; i++) {
        amount[i] = 1;
      }
      amount[slot] = ep;
      active = slot;
    } else {
      final u = 2 * count - 1 - slot;
      for (var i = 0; i < u; i++) {
        amount[i] = 1;
      }
      amount[u] = 1 - ep;
      active = u;
    }
  }
  return _SolveCycle(amount, active);
}

(double, double, double, bool) _applyMoves(
  (double, double, double) pt3,
  List<_Move> moves,
  _SolveCycle sc,
) {
  var (x, y, z) = pt3;
  var inActive = false;
  for (var i = 0; i < moves.length; i++) {
    if (sc.amount[i] <= 0) continue;
    final mv = moves[i];
    final coord = mv.axis == 0 ? x : (mv.axis == 1 ? y : z);
    if (coord < mv.lo || coord >= mv.hi) continue;
    if (i == sc.active) inActive = true;
    final a = mv.ang * sc.amount[i];
    final ca = math.cos(a);
    final sa = math.sin(a);
    if (mv.axis == 0) {
      final y2 = y * ca - z * sa;
      z = y * sa + z * ca;
      y = y2;
    } else if (mv.axis == 1) {
      final x2 = x * ca + z * sa;
      z = -x * sa + z * ca;
      x = x2;
    } else {
      final x2 = x * ca - y * sa;
      y = x * sa + y * ca;
      x = x2;
    }
  }
  return (x, y, z, inActive);
}

List<_Move> _makeMoves(int count) {
  final moves = <_Move>[];
  for (var i = 0; i < count; i++) {
    final axis = math.min(2, (hashD(i.toDouble(), 2.3) * 3).floor());
    final lo = -1.0 + 0.5 * math.min(3, (hashD(i.toDouble(), 5.9) * 4).floor());
    final dir = hashD(i.toDouble(), 7.7) < 0.5 ? 1 : -1;
    moves.add(_Move(axis: axis, lo: lo, hi: lo + 0.5, ang: dir * math.pi / 2));
  }
  return moves;
}

// --- Globe: lat/long field, a scan meridian sweeps — searching --------

void drawGlobe(Canvas canvas, double size, double t, bool dark, ModeOpts o) {
  const spin = 0.5;
  final cx = size / 2;
  final cy = size / 2;
  final radius = (size / 2) * 0.82;
  final tilt = 0.4 + 0.06 * math.sin(t * 0.35);
  final pt = makeProj(t * spin, tilt, cx, cy, radius);
  // scan sweeps relative to the spin; scanMul scales that relative rate
  final scan = t * (spin + (1.7 - spin) * (o['scanMul'] ?? 1));
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);
  final dimBase = o['dimBase'] ?? 1;

  final dots = <Dot>[];
  final latRings = (o['latRings'] ?? 17).round();
  final lonDensity = o['lonDensity'] ?? 44;
  for (var li = 0; li <= latRings; li++) {
    final lat = -math.pi / 2 + (li / latRings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final (px, py, z) = pt(cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon));
      final depth = (z + 1) / 2;
      // the scan: a moving meridian read as a size ripple, not a shine
      final d = angleDelta(lon + t * spin, scan);
      final boost = math.exp(-(d * d) / 0.18) * math.max(0.0, z);
      dots.add(Dot(
        x: px,
        y: py,
        z: z,
        r: ((o['rBase'] ?? 0.6) + (o['rDepth'] ?? 1.7) * depth + (o['rBoost'] ?? 1) * boost) * rs,
        white: (o['inkFar'] ?? 0.62) - (o['inkSpan'] ?? 0.54) * depth,
        // dimBase < 1 fades un-scanned dots so the meridian reads clearly
        a: dimBase + (1 - dimBase) * math.min(1.0, boost),
      ));
    }
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3);
}

// --- Rubik: bands twist in quarter turns, scramble → solve — solving --

void drawRubik(Canvas canvas, double size, double t, bool dark, ModeOpts o) {
  final cx = size / 2;
  final cy = size / 2;
  final bigR = (size / 2) * 0.82;
  final pt = makeProj(t * 0.55, 0.35 + 0.1 * math.sin(t * 0.9), cx, cy, bigR);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);
  final moveCount = (o['moveCount'] ?? 14).round();
  final moves = _makeMoves(moveCount);
  final sc = _solveCycle(t, moveCount, 0.42, 1.2);

  final dots = <Dot>[];
  final latRings = (o['latRings'] ?? 15).round();
  final lonDensity = o['lonDensity'] ?? 40;
  for (var li = 0; li <= latRings; li++) {
    final lat = -math.pi / 2 + (li / latRings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    final lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final (x, y, z, inActive) = _applyMoves(
        (cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon)),
        moves,
        sc,
      );
      final (px, py, zr) = pt(x, y, z);
      final depth = (zr + 1) / 2;
      // the band being turned inks a touch darker — the "hand"
      dots.add(Dot(
        x: px,
        y: py,
        z: zr,
        r: ((o['rBase'] ?? 0.6) + (o['rDepth'] ?? 1.7) * depth + (inActive ? (o['rActive'] ?? 0.3) : 0)) * rs,
        white: (o['inkFar'] ?? 0.62) - (o['inkSpan'] ?? 0.54) * depth - (inActive ? 0.14 : 0),
      ));
    }
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3);
}

// --- Wave: a waveform rolls through the rings — listening -------------

void drawWave(Canvas canvas, double size, double t, bool dark, ModeOpts o) {
  final cx = size / 2;
  final cy = size / 2;
  // 0.76 base × 1.15 — the undulation pulls the sphere inward, so wave read
  // ~15% smaller than the other lattice modes; scaled up to match them
  final bigR = (size / 2) * 0.874;
  final pt = makeProj(t * 0.18, 0.38, cx, cy, 1);
  final rs = radiusScale(size, o['rsPow'] ?? 0.6);

  final dots = <Dot>[];
  final rings = (o['rings'] ?? 15).round();
  final lonDensity = o['lonDensity'] ?? 40;
  for (var ri = 0; ri <= rings; ri++) {
    final lat = -math.pi / 2 + (ri / rings) * math.pi;
    final cosLat = math.cos(lat);
    final sinLat = math.sin(lat);
    // two waves, different tempi — organic, never quite repeating
    final w = 0.62 * math.sin(t * 2.1 - ri * 0.52) + 0.38 * math.sin(t * 1.27 + ri * 0.83);
    final rr = bigR * (0.88 + 0.105 * w);
    final lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
    for (var lj = 0; lj < lonCount; lj++) {
      final lon = (lj / lonCount) * 2 * math.pi;
      final (px, py, z) = pt(
        cosLat * math.cos(lon) * rr,
        sinLat * rr,
        cosLat * math.sin(lon) * rr,
      );
      final depth = (z / bigR + 1) / 2;
      final crest = math.max(0.0, w);
      dots.add(Dot(
        x: px,
        y: py,
        z: z,
        r: ((o['rBase'] ?? 0.6) + (o['rDepth'] ?? 1.7) * depth) * (1 + 0.4 * crest) * rs,
        white: 0.66 - 0.56 * depth - 0.1 * crest,
      ));
    }
  }
  paintDots(canvas, dots, dark, o['rMin'] ?? 0.3);
}
