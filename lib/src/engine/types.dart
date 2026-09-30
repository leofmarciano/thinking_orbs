// Engine-level contracts shared by every mode implementation.

import 'dart:ui';

import 'core.dart';
import 'profiles.dart';

export 'core.dart' show Dot, Line, OrbFrame;

/// Geometry for one instant: pure math over (size, t, opts), no rendering
/// surface and no theme — `dark` only affects ink at paint time.
///
/// Deliberately free of Flutter types so its output can be compared
/// numerically against the upstream golden vectors in pure Dart tests.
typedef ModeFrame = OrbFrame Function(double size, double t, ModeOpts opts);

/// One frame painter: draws a mode onto a [Canvas] at logical-px `size`.
typedef ModeDraw = void Function(
    Canvas canvas, double size, double t, bool dark, ModeOpts opts,
    [Color? color]);
