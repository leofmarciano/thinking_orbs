// Engine-level contracts shared by every mode implementation.

import 'dart:ui';

import 'profiles.dart';

export 'core.dart' show Dot;

/// One frame painter: draws a mode onto a [Canvas] at logical-px `size`.
typedef ModeDraw = void Function(
  Canvas canvas,
  double size,
  double t,
  bool dark,
  ModeOpts opts,
);
