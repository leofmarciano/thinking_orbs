// Parity test against the upstream frozen frames. Every golden case runs
// this port's modeFrames and compares dots/lines field-by-field within the
// golden tolerance. Fixtures are verbatim copies of the upstream spec
// (thinking-orbs v0.3.1):
//   test/fixtures/orbs-golden.json — 72 cases (9 states × 2 sizes × 4
//     timestamps), dots stride 6 (x,y,z,r,white,a), lines stride 7
//     (x1,y1,x2,y2,white,a,w), dots in draw order (z ascending).
//   test/fixtures/orbs-spec.json — enums, stateToMode, labels, profiles.
//
// One deliberate comparison refinement: dots are compared inside maximal
// runs of nearly-equal z (gap <= _tieEps on either side's sorted list)
// rather than strictly positionally. Both lists are z-ascending and hold
// the same dots, but ring's face-on band projects a whole lane onto
// z = 0 with the only differences being ~1e-50 cancellation residue —
// upstream's exact order there is decided by the last ulp of V8's
// transcendentals, which Dart's math can differ from by 1 ulp (we emit the
// same residues, permuted). Positional comparison across such ties would
// test V8's libm, not the port's geometry. Values inside a tie run are
// still compared field-by-field at the golden tolerance. (morph emits
// every dot at z = 0 — a single tie window — so only its field values,
// not its ordering, are verified by the multiset compare; draw order is
// asserted separately per case.)

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/src/engine/profiles.dart';
import 'package:thinking_orbs/thinking_orbs.dart';

/// Z-gap below which two dots are considered tied. Must clear the fixture's
/// 6-decimal rounding noise (|golden z - true z| <= 5e-7) plus FP residue
/// between true ties (~1e-13), yet stay under the smallest genuine inter-dot
/// z separation observed in the goldens (5e-6).
const double _tieEps = 2e-6;

void main() {
  final golden = jsonDecode(
    File('test/fixtures/orbs-golden.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final spec = jsonDecode(
    File('test/fixtures/orbs-spec.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final tol = (golden['tolerance'] as num).toDouble();
  final statesByName = OrbState.values.asNameMap();

  OrbSize sizeFor(num px) => px == 64 ? OrbSize.size64 : OrbSize.size20;

  group('resolved presets', () {
    final resolved = golden['resolved'] as Map<String, dynamic>;
    for (final entry in resolved.entries) {
      test(entry.key, () {
        final dash = entry.key.lastIndexOf('-');
        final state = statesByName[entry.key.substring(0, dash)]!;
        final size = sizeFor(num.parse(entry.key.substring(dash + 1)));
        final r = resolvePreset(state, size);
        final want = entry.value as Map<String, dynamic>;
        expect(r.mode, want['mode']);
        expect(r.speed, closeTo((want['speed'] as num).toDouble(), tol));
        final wantOpts = (want['opts'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        for (final kv in wantOpts.entries) {
          expect(r.opts[kv.key], closeTo(kv.value, tol),
              reason: 'opt ${kv.key}');
        }
        expect(r.opts.length, wantOpts.length,
            reason: 'extra opts: '
                '${r.opts.keys.where((k) => !wantOpts.containsKey(k))}');
      });
    }
  });

  group('golden frames', () {
    for (final c in golden['cases'] as List<dynamic>) {
      final key = c['key'] as String;
      test(key, () {
        final state = statesByName[c['state'] as String]!;
        final size = sizeFor(c['size'] as num);
        final r = resolvePreset(state, size);
        expect(r.mode, c['mode']);

        // Golden t is the engine clock — call the frame fn with raw t,
        // NOT multiplied by the preset speed.
        final frame =
            modeFrames[r.mode]!(size.px, (c['t'] as num).toDouble(), r.opts);

        final gdots = c['dots'] as List<dynamic>;
        final glines = c['lines'] as List<dynamic>;
        expect(frame.dots.length, c['dotCount'], reason: 'dotCount');
        expect(frame.lines.length, c['lineCount'], reason: 'lineCount');

        final mismatches = <String>[];

        // The tie-window multiset compare below tolerates permutations
        // inside a near-tie run, so it cannot itself catch a broken sort —
        // a descending frame would collapse into one window and pass.
        // Assert draw order separately: z must be non-decreasing.
        for (var k = 1; k < frame.dots.length; k++) {
          expect(
            frame.dots[k].z,
            greaterThanOrEqualTo(frame.dots[k - 1].z - _tieEps),
            reason: 'dot[$k] z=${frame.dots[k].z} is behind '
                'dot[${k - 1}] z=${frame.dots[k - 1].z} '
                '— not z-ascending',
          );
        }

        // --- dots: z-ascending, compared inside near-tie windows ---
        double gz(int i) => (gdots[i * 6 + 2] as num).toDouble();
        bool dotMatches(int gi, Dot d) {
          final got = [d.x, d.y, d.z, d.r, d.white, d.a ?? 1];
          for (var f = 0; f < 6; f++) {
            if ((got[f] - (gdots[gi * 6 + f] as num).toDouble()).abs() > tol) {
              return false;
            }
          }
          return true;
        }

        const dotFields = ['x', 'y', 'z', 'r', 'white', 'a'];
        String fmtDot(int gi) => [
              for (var f = 0; f < 6; f++) '${dotFields[f]}=${gdots[gi * 6 + f]}'
            ].join(',');

        final gn = gdots.length ~/ 6;
        var i = 0; // golden cursor
        var j = 0; // ours cursor
        while (i < gn && j < frame.dots.length) {
          // Window = union of both lists' tie runs starting here; grow
          // while either head's z stays within _tieEps of the window max.
          var gi = i + 1;
          var oj = j + 1;
          var hi = math.max(gz(i), frame.dots[j].z);
          var grew = true;
          while (grew) {
            grew = false;
            while (gi < gn && gz(gi) <= hi + _tieEps) {
              hi = math.max(hi, gz(gi));
              gi++;
              grew = true;
            }
            while (oj < frame.dots.length && frame.dots[oj].z <= hi + _tieEps) {
              hi = math.max(hi, frame.dots[oj].z);
              oj++;
              grew = true;
            }
          }
          // Multiset-compare golden[i, gi) against ours[j, oj) via
          // bipartite matching (Kuhn's augmenting paths) — first-fit would
          // fail when two golden dots are both within tol of one of ours.
          final omatch = <int, int>{}; // our dot idx -> golden idx
          bool aug(int g, Set<int> vis) {
            for (var k = j; k < oj; k++) {
              if (vis.contains(k) || !dotMatches(g, frame.dots[k])) {
                continue;
              }
              vis.add(k);
              final occ = omatch[k];
              if (occ == null || aug(occ, vis)) {
                omatch[k] = g;
                return true;
              }
            }
            return false;
          }

          for (var gi2 = i; gi2 < gi; gi2++) {
            if (!aug(gi2, <int>{}) && mismatches.length < 20) {
              mismatches.add('dot[$gi2]: no match for golden ${fmtDot(gi2)}');
            }
          }
          for (var k = j; k < oj; k++) {
            if (!omatch.containsKey(k) && mismatches.length < 20) {
              final d = frame.dots[k];
              mismatches.add('extra dot[$k]: '
                  'x=${d.x},y=${d.y},z=${d.z},r=${d.r},'
                  'white=${d.white},a=${d.a ?? 1}');
            }
          }
          i = gi;
          j = oj;
        }
        if (i < gn) mismatches.add('${gn - i} golden dots left unmatched');
        if (j < frame.dots.length) {
          mismatches.add('${frame.dots.length - j} extra dots');
        }

        // --- lines: drawn first in insertion order, positional compare ---
        const lineFields = ['x1', 'y1', 'x2', 'y2', 'white', 'a', 'w'];
        for (var li = 0; li < frame.lines.length; li++) {
          final l = frame.lines[li];
          final got = [l.x1, l.y1, l.x2, l.y2, l.white, l.a ?? 1, l.w];
          for (var f = 0; f < lineFields.length; f++) {
            final want = (glines[li * 7 + f] as num).toDouble();
            if ((got[f] - want).abs() > tol) {
              mismatches
                  .add('line[$li].${lineFields[f]}: got ${got[f]}, want $want');
            }
          }
        }

        expect(mismatches, isEmpty,
            reason: '${mismatches.length} mismatched fields:\n'
                '${mismatches.take(20).join('\n')}');
      });
    }
  });

  group('orbs-spec conformance', () {
    test('OrbState names and order match spec.enums.states', () {
      final states = (spec['enums']['states'] as List).cast<String>();
      expect(OrbState.values.map((s) => s.name).toList(), states);
    });

    test('mode registry matches spec.enums.modes', () {
      final modes = (spec['enums']['modes'] as List).cast<String>();
      expect(modeFrames.keys.toList(), modes);
      expect(modeDraws.keys.toList(), modes);
    });

    test('stateToMode matches spec', () {
      final map = spec['stateToMode'] as Map<String, dynamic>;
      for (final e in map.entries) {
        expect(stateToMode[statesByName[e.key]], e.value, reason: e.key);
      }
      expect(stateToMode.length, map.length);
    });

    test('base profiles match spec.baseProfiles', () {
      final modes = (spec['enums']['modes'] as List).cast<String>();
      final profiles = spec['baseProfiles'] as Map<String, dynamic>;
      for (final mode in modes) {
        final want = profiles[mode] as Map<String, dynamic>;
        for (final kv in want.entries) {
          expect(
            baseProfiles[mode]?[kv.key],
            closeTo((kv.value as num).toDouble(), 1e-9),
            reason: '$mode.${kv.key}',
          );
        }
        expect(baseProfiles[mode]?.length, want.length, reason: mode);
      }
    });

    testWidgets('default semantic labels match spec.labels', (tester) async {
      final labels = spec['labels'] as Map<String, dynamic>;
      for (final state in OrbState.values) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: ThinkingOrb(state: state, paused: true),
            ),
          ),
        );
        expect(
          find.bySemanticsLabel(labels[state.name] as String),
          findsOneWidget,
          reason: state.name,
        );
      }
    });
  });
}
