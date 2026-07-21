// Not a regular test: renders one frame per state × size to PNG so the
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
        for (final (name, dark) in [('dark', true), ('light', false)]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          final px = size.px * scale;
          canvas.drawRect(
            Rect.fromLTWH(0, 0, px, px),
            Paint()..color = dark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA),
          );
          canvas.scale(scale);
          // a mid-animation representative frame, like the reduced-motion one
          draw(canvas, size.px, 0.6 * resolved.speed, dark, resolved.opts);
          final image = await recorder.endRecording().toImage(px.round(), px.round());
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/${state.name}_${size.px.round()}_$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    }
  });
}
