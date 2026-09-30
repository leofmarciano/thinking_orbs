// Mode key → geometry builder. Kept separate from the presets so unused
// modes can in principle be dropped in custom builds.

import 'dart:ui';

import 'braid.dart';
import 'core.dart';
import 'lattice.dart';
import 'morph.dart';
import 'orbits.dart';
import 'profiles.dart';
import 'ribbon.dart';
import 'types.dart';
import 'web.dart';

/// The portable surface: pure geometry, no canvas. Frame functions are
/// `dart:ui`-free, so their output can be compared numerically against the
/// upstream golden vectors.
const Map<String, ModeFrame> modeFrames = {
  'orbits': frameOrbits,
  'globe': frameGlobe,
  'rubik': frameRubik,
  'wave': frameWave,
  'web': frameWeb,
  'braid': frameBraid,
  'ribbon': frameRibbon,
  // ring shares ribbon's geometry — the `faceOn` profile flag switches it
  'ring': frameRibbon,
  'morph': frameMorph,
};

/// Canvas painters, derived from the geometry. Lines are drawn first so
/// nodes sit on top of their edges.
final Map<String, ModeDraw> modeDraws = {
  for (final e in modeFrames.entries)
    e.key: (Canvas canvas, double size, double t, bool dark, ModeOpts opts,
            [Color? color]) =>
        paintFrame(canvas, e.value(size, t, opts), dark, color),
};
