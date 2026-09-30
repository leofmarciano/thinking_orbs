// Not a regular test: renders release artwork. Run with:
//   flutter test test/preview_render.dart
// Outputs:
//   doc/preview.png        — still grid, all 9 states × dark/light @64px
//   build/preview/         — per-state × size × palette PNGs (debug)
//   build/anim/frame_*.png — animation frames; assemble with ffmpeg, e.g.
//   ffmpeg -framerate 15 -i build/anim/frame_%03d.png \
//     -filter_complex "[0]reverse[r];[0][r]concat=n=2:v=1,split[a][b];
//     [a]palettegen[p];[b][p]paletteuse" doc/preview.gif

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/thinking_orbs.dart';

const _darkBg = Color(0xFF09090B);
const _lightBg = Color(0xFFFAFAFA);

/// Logical-pitch between cells; the 64 px orb sits centered in the cell.
const _cellPitch = 80.0;
const _orbSize = OrbSize.size64;

/// Raw engine t used for the still grid — the same instant the widget's
/// reduced-motion frame and the upstream golden vectors use.
const _stillT = 0.6;

Future<ui.Image> _render(double w, double h, void Function(Canvas) paint) {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  return recorder.endRecording().toImage(w.round(), h.round());
}

/// Draw `state`'s orb into `canvas` at (left, top) at raw engine time `t`.
void _drawOrb(
    Canvas canvas, OrbState state, bool dark, double t, double left, double top,
    [Color? color]) {
  final resolved = resolvePreset(state, _orbSize);
  canvas.save();
  canvas.translate(left, top);
  modeDraws[resolved.mode]!(
    canvas,
    _orbSize.px,
    t,
    dark,
    resolved.opts,
    color,
  );
  canvas.restore();
}

/// Left x of the orb inside cell `index` (logical units).
double _cellX(int index) => index * _cellPitch + (_cellPitch - _orbSize.px) / 2;

/// Count pixels whose color differs from `bg` — used to assert every
/// state actually drew something inside its cell.
Future<int> _inkedPixels(ui.Image img, Rect cell, Color bg) async {
  final data = await img.toByteData();
  final bytes = data!.buffer.asUint8List();
  final stride = img.width * 4;
  var inked = 0;
  final bgValue = bg.toARGB32();
  for (var y = cell.top.round(); y < cell.bottom.round(); y++) {
    for (var x = cell.left.round(); x < cell.right.round(); x++) {
      final o = y * stride + x * 4;
      final px = (bytes[o + 3] << 24) |
          (bytes[o] << 16) |
          (bytes[o + 1] << 8) |
          bytes[o + 2];
      if (px != bgValue) inked++;
    }
  }
  return inked;
}

Future<void> _writePng(ui.Image img, String path) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

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
          final px = size.px * scale;
          final img = await _render(px, px, (canvas) {
            canvas.drawRect(
              Rect.fromLTWH(0, 0, px, px),
              Paint()..color = variant.dark ? _darkBg : _lightBg,
            );
            canvas.scale(scale);
            // the reduced-motion representative frame
            draw(
              canvas,
              size.px,
              _stillT,
              variant.dark,
              resolved.opts,
              variant.color,
            );
          });
          await _writePng(
            img,
            '${dir.path}/${state.name}_${size.px.round()}_${variant.name}.png',
          );
        }
      }
    }
  });

  test('render doc/preview.png grid', () async {
    Directory('doc').createSync();
    const scale = 3.0;
    const rows = <(bool, Color)>[(true, _darkBg), (false, _lightBg)];
    final w = OrbState.values.length * _cellPitch * scale;
    final h = rows.length * _cellPitch * scale;

    final img = await _render(w, h, (canvas) {
      canvas.scale(scale);
      for (var r = 0; r < rows.length; r++) {
        canvas.drawRect(
          Rect.fromLTWH(0, r * _cellPitch, OrbState.values.length * _cellPitch,
              _cellPitch),
          Paint()..color = rows[r].$2,
        );
      }
      final orbTop = (_cellPitch - _orbSize.px) / 2;
      for (var c = 0; c < OrbState.values.length; c++) {
        for (var r = 0; r < rows.length; r++) {
          _drawOrb(
            canvas,
            OrbState.values[c],
            rows[r].$1,
            _stillT,
            _cellX(c),
            r * _cellPitch + orbTop,
          );
        }
      }
    });
    await _writePng(img, 'doc/preview.png');

    // Every state's cell must contain drawn ink on both palettes.
    for (var c = 0; c < OrbState.values.length; c++) {
      for (var r = 0; r < rows.length; r++) {
        final cell = Rect.fromLTWH(
          c * _cellPitch * scale,
          r * _cellPitch * scale,
          _cellPitch * scale,
          _cellPitch * scale,
        );
        final inked = await _inkedPixels(img, cell, rows[r].$2);
        expect(
          inked,
          greaterThan(50),
          reason: '${OrbState.values[c].name} '
              '${rows[r].$1 ? "dark" : "light"} cell looks empty',
        );
      }
    }
  });

  test('render animation frames', () async {
    final dir = Directory('build/anim');
    dir.createSync(recursive: true);
    const scale = 2.0;
    const fps = 15;
    const seconds = 4.0;
    final w = OrbState.values.length * _cellPitch * scale;
    const h = _cellPitch * scale;
    final frames = (seconds * fps).round();

    for (var f = 0; f < frames; f++) {
      final t = f / fps;
      final img = await _render(w, h, (canvas) {
        canvas.scale(scale);
        canvas.drawRect(
          Rect.fromLTWH(0, 0, OrbState.values.length * _cellPitch, _cellPitch),
          Paint()..color = _darkBg,
        );
        final orbTop = (_cellPitch - _orbSize.px) / 2;
        for (var c = 0; c < OrbState.values.length; c++) {
          final state = OrbState.values[c];
          // elapsed seconds × preset speed, same as the widget's clock
          final tEngine = t * resolvePreset(state, _orbSize).speed;
          _drawOrb(canvas, state, true, tEngine, _cellX(c), orbTop);
        }
      });
      await _writePng(
        img,
        '${dir.path}/frame_${f.toString().padLeft(3, '0')}.png',
      );
    }
  });
}
