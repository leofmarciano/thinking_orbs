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
      expect(resolvePreset(OrbState.composing, OrbSize.size64).mode, 'ribbon');
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
      expect(r.opts['iconD'], closeTo(0.54, 1e-9));
      expect(r.opts['spread'], 1.45);
      expect(r.opts['rDot'], closeTo(0.021 * 0.395, 1e-9));
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
