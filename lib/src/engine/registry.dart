// Mode key → frame painter. Kept separate from the presets so unused
// modes can in principle be dropped in custom builds.

import 'lattice.dart';
import 'morph.dart';
import 'orbits.dart';
import 'ribbon.dart';
import 'types.dart';

const Map<String, ModeDraw> modeDraws = {
  'orbits': drawOrbits,
  'globe': drawGlobe,
  'rubik': drawRubik,
  'wave': drawWave,
  'ribbon': drawRibbon,
  'morph': drawMorph,
};
