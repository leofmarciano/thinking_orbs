import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/thinking_orbs.dart';

void main() {
  group('resolvePreset', () {
    test('maps every state to its mode', () {
      expect(resolvePreset(OrbState.working, OrbSize.size64).mode, 'orbits');
      expect(resolvePreset(OrbState.searching, OrbSize.size64).mode, 'globe');
      expect(resolvePreset(OrbState.solving, OrbSize.size64).mode, 'rubik');
      expect(resolvePreset(OrbState.listening, OrbSize.size64).mode, 'wave');
      expect(resolvePreset(OrbState.connecting, OrbSize.size64).mode, 'web');
      expect(resolvePreset(OrbState.weaving, OrbSize.size64).mode, 'braid');
      expect(resolvePreset(OrbState.composing, OrbSize.size64).mode, 'ribbon');
      expect(resolvePreset(OrbState.breathing, OrbSize.size64).mode, 'ring');
      expect(resolvePreset(OrbState.shaping, OrbSize.size64).mode, 'morph');
    });

    test('orbits/64 is the unscaled base profile', () {
      final r = resolvePreset(OrbState.working, OrbSize.size64);
      expect(r.speed, 1.885);
      expect(r.opts['orbitN'], 12);
      expect(r.opts['ghostN'], 40);
      expect(r.opts['ghostR'], 0.9);
      expect(r.opts['partR'], 1.2);
      expect(r.opts['partRDepth'], 1.6);
    });

    test('orbits/20 scales counts linearly and radii by the size mul', () {
      // count 0.238: orbitN = round(12*0.238) = 3, ghostN = round(40*0.238) = 10
      // size 2.4: ghostR = 0.9*2.4, partR = 1.2*2.4, partRDepth = 1.6*2.4
      final r = resolvePreset(OrbState.working, OrbSize.size20);
      expect(r.speed, 3.9);
      expect(r.opts['orbitN'], 3);
      expect(r.opts['ghostN'], 10);
      expect(r.opts['ghostR'], closeTo(0.9 * 2.4, 1e-9));
      expect(r.opts['partR'], closeTo(1.2 * 2.4, 1e-9));
      expect(r.opts['partRDepth'], closeTo(1.6 * 2.4, 1e-9));
      expect(r.opts['rSizeMul'], closeTo(2.4, 1e-9));
    });

    test('globe/64 scales the lattice pair by sqrt(count) and merges extras',
        () {
      // count 0.42: sqrt = 0.64807...; latRings = round(17*rt) = 11,
      // lonDensity = round(44*rt) = 29
      final r = resolvePreset(OrbState.searching, OrbSize.size64);
      expect(r.speed, 2.015);
      expect(r.opts['latRings'], 11);
      expect(r.opts['lonDensity'], 29);
      expect(r.opts['rBase'], closeTo(0.6 * 1.15, 1e-9));
      expect(r.opts['scanMul'], 4.08);
      expect(r.opts['dimBase'], 0.45);
    });

    test('ribbon presets freeze the spin and widen the band', () {
      final r64 = resolvePreset(OrbState.composing, OrbSize.size64);
      expect(r64.opts['spin'], 0);
      expect(r64.opts['bandMul'], 3.9);
      final r20 = resolvePreset(OrbState.composing, OrbSize.size20);
      expect(r20.opts['spin'], 0);
      expect(r20.opts['bandMul'], 4.94);
    });

    test('morph scales iconD by count and carries spread', () {
      final r = resolvePreset(OrbState.shaping, OrbSize.size64);
      expect(r.speed, 2.405);
      expect(r.opts['iconD'], closeTo(0.702, 1e-9));
      expect(r.opts['spread'], 1.45);
      expect(r.opts['rDot'], closeTo(0.021 * 0.395, 1e-9));
    });

    test('ring opts out of the ghost layer (explicit 0 survives scaling)', () {
      final r = resolvePreset(OrbState.breathing, OrbSize.size64);
      expect(r.mode, 'ring');
      expect(r.opts['ghostN'], 0);
      expect(r.opts['faceOn'], 1);
    });

    test('resolution is cached', () {
      final a = resolvePreset(OrbState.working, OrbSize.size64);
      final b = resolvePreset(OrbState.working, OrbSize.size64);
      expect(identical(a, b), isTrue);
    });
  });

  group('mode painters', () {
    test('every state × size × t paints without throwing', () {
      for (final state in OrbState.values) {
        for (final size in OrbSize.values) {
          final resolved = resolvePreset(state, size);
          final draw = modeDraws[resolved.mode]!;
          for (final t in [0.0, 0.6, 1.7, 5.3, 42.0]) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            draw(canvas, size.px, t * resolved.speed, true, resolved.opts);
            draw(canvas, size.px, t * resolved.speed, false, resolved.opts);
            draw(
              canvas,
              size.px,
              t * resolved.speed,
              true,
              resolved.opts,
              const Color(0xFF8B5CF6),
            );
            recorder.endRecording();
          }
        }
      }
    });
  });

  group('JS numeric semantics', () {
    test('non-integer counts iterate like the upstream loops', () {
      // upstream `for (i = 0; i < n; i++)` runs on the raw double: ceil(n)
      // iterations — .round() would give one fewer when frac(n) < .5
      final orbits = modeFrames['orbits']!(64, 0, const {
        'orbitN': 2.4, // JS: 3 orbits; rounded would give 2
        'ghostN': 0.0,
        'particles': 1.0,
      });
      expect(orbits.dots.length, 3);

      // upstream `i <= n` runs floor(n)+1 — latRings 2.6 → li = 0,1,2
      // (rounded to 3, `li <= 3` would give a 4th ring)
      final globe = modeFrames['globe']!(64, 0, const {
        'latRings': 2.6,
        'lonDensity': 1.0, // one dot per ring
      });
      expect(globe.dots.length, 3);

      // a non-integer moveCount still iterates ceil() moves upstream
      // (though upstream's new Array(count) throws before they render —
      // we allocate count.ceil() and render instead of crashing)
      expect(
        () => modeFrames['rubik']!(64, 0, const {'moveCount': 2.5}),
        returnsNormally,
      );
    });

    test('negative t follows truncated JS % semantics', () {
      // JS `t % cyc` keeps the dividend's sign → negative tc → shape
      // index -1 → upstream crashes on CYCLE[-1]; we wrap the phase into
      // the cycle instead, so t<0 renders the periodic extension — a
      // finite, non-empty frame equal to the matching positive-time one.
      final neg = modeFrames['morph']!(64, -0.5, const {});
      expect(neg.dots, isNotEmpty);
      for (final d in neg.dots) {
        expect(d.x.isFinite && d.y.isFinite && d.r.isFinite, isTrue);
      }
      final wrapped = modeFrames['morph']!(64, -0.5 + 6.9, const {});
      expect(neg.dots.length, wrapped.dots.length);
      for (var i = 0; i < neg.dots.length; i++) {
        expect(neg.dots[i].x, closeTo(wrapped.dots[i].x, 1e-9));
        expect(neg.dots[i].y, closeTo(wrapped.dots[i].y, 1e-9));
      }

      // rubik: negative tc leaves every move amount 0 (upstream's writes
      // are dead property sets) — the frame must render as the untouched
      // lattice, identical to moveCount = 0 at the same t. Euclidean %
      // would wrap tc into an active slot and apply moves.
      final moved = modeFrames['rubik']!(64, -2, const {'moveCount': 14});
      final unmoved = modeFrames['rubik']!(64, -2, const {'moveCount': 0});
      expect(moved.dots.length, unmoved.dots.length);
      for (var i = 0; i < moved.dots.length; i++) {
        expect(moved.dots[i].x, unmoved.dots[i].x, reason: 'dot[$i].x');
        expect(moved.dots[i].y, unmoved.dots[i].y, reason: 'dot[$i].y');
      }
    });

    test('no mode throws for finite negative t or degenerate counts', () {
      const weird = <ModeOpts>[
        {},
        {'orbitN': -1, 'ghostN': -1, 'particles': -1},
        {'nodeN': 0, 'signals': 3},
        {'nodeN': -2, 'signals': 3},
        {'latRings': 0},
        {'rings': 0},
        {'moveCount': -2},
        {'ghostN': 0, 'strandN': 0},
        {'segs': 0, 'lanes': 0},
      ];
      for (final m in modeFrames.keys) {
        for (final t in [-13.7, -0.5, 0.0, 1.7]) {
          for (final opts in weird) {
            expect(
              () => modeFrames[m]!(64, t, opts),
              returnsNormally,
              reason: '$m t=$t $opts',
            );
          }
        }
      }
    });
  });

  group('ThinkingOrb widget', () {
    testWidgets('builds with default semantics label', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: ThinkingOrb()),
        ),
      );
      expect(find.bySemanticsLabel('Working…'), findsOneWidget);
      final box = tester.getSize(find.byType(ThinkingOrb));
      expect(box, const Size(64, 64));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('honours size, custom label and paused', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ThinkingOrb(
              state: OrbState.searching,
              size: OrbSize.size20,
              paused: true,
              semanticLabel: 'Analysing repository…',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Analysing repository…'), findsOneWidget);
      expect(tester.getSize(find.byType(ThinkingOrb)), const Size(20, 20));
      // paused → no pending animation frames
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('animates when not paused', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: ThinkingOrb(state: OrbState.listening)),
        ),
      );
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('accepts and updates a custom color', (tester) async {
      const violet = Color(0xFF8B5CF6);
      const emerald = Color(0xFF34D399);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ThinkingOrb(color: violet, paused: true),
          ),
        ),
      );
      expect(
          tester.widget<ThinkingOrb>(find.byType(ThinkingOrb)).color, violet);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ThinkingOrb(color: emerald, paused: true),
          ),
        ),
      );
      expect(
        tester.widget<ThinkingOrb>(find.byType(ThinkingOrb)).color,
        emerald,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
