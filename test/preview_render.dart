// Not a regular test: renders one frame per state × size × palette to PNG so the
// port can be visually compared against the original demo. Run with:
//   flutter test test/preview_render.dart
// Output lands in build/preview/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/thinking_orbs.dart';

Future<void> main() async {
  test('render preview frames', () async {
    final dir = Directory('build/preview');
    dir.createSync(recursive: true);
    const scale = 4.0; // upscale for easier eyeballing
    for (final state in OrbState.values) {
      for (final size in OrbSize.values) {
        final resolved = resolvePreset(state, size);
        final draw = modeDraws[resolved.mode]!;
        const variants = <({String name, bool dark, Color? color})>[
          (name: 'dark', dark: true, color: null),
          (name: 'light', dark: false, color: null),
          (name: 'violet_dark', dark: true, color: Color(0xFF8B5CF6)),
          (name: 'violet_light', dark: false, color: Color(0xFF8B5CF6)),
        ];
        for (final variant in variants) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final px = size.px * scale;
          canvas.drawRect(
            Rect.fromLTWH(0, 0, px, px),
            Paint()
              ..color = variant.dark
                  ? const Color(0xFF09090B)
                  : const Color(0xFFFAFAFA),
          );
          canvas.scale(scale);
          // a mid-animation representative frame, like the reduced-motion one
          draw(
            canvas,
            size.px,
            0.6 * resolved.speed,
            variant.dark,
            resolved.opts,
            variant.color,
          );
          final image =
              await recorder.endRecording().toImage(px.round(), px.round());
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/${state.name}_${size.px.round()}_${variant.name}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    }
  });
}
