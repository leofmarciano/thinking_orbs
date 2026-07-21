// Density profiles + the multiplier machinery that scales them. The base
// rows are the original inkform `fine` profiles; each shipped preset
// (state × size) applies count / radius multipliers on top, resolved once
// per (state, size) pair.

import 'dart:math' as math;

/// A flat bag of numeric knobs consumed by the mode painters.
typedef ModeOpts = Map<String, double>;

// 2-D lattices (rings × dots-per-ring) come in pairs — each side takes
// √scale so the TOTAL dot count scales by `scale`; flat lists scale
// linearly. `iconD` sets the morph outline's sampling density.
const List<(String, String)> _countPairs = [
  ('latRings', 'lonDensity'),
  ('rings', 'lonDensity'),
  ('lanes', 'segs'),
];
const List<String> _countKeys = ['orbitN', 'ghostN'];
const List<String> _iconDensityKeys = ['iconD'];

// Every key that sets a dot's rendered radius — scaling all of them keeps
// a dot's near/far falloff intact while shrinking or growing the mark.
const List<String> _radiusKeys = [
  'rBase',
  'rDepth',
  'rActive',
  'rDot',
  'ghostR',
  'partR',
  'partRDepth',
];

ModeOpts scaleCounts(ModeOpts opts, double scale) {
  final out = Map<String, double>.from(opts);
  final done = <String>{};
  final rt = math.sqrt(scale);
  for (final (a, b) in _countPairs) {
    final va = out[a];
    final vb = out[b];
    if (va != null && vb != null && !done.contains(a) && !done.contains(b)) {
      out[a] = math.max(2, (va * rt).round()).toDouble();
      out[b] = math.max(2, (vb * rt).round()).toDouble();
      done.add(a);
      done.add(b);
    }
  }
  for (final k in _countKeys) {
    final v = out[k];
    if (v != null && !done.contains(k)) {
      out[k] = math.max(1, (v * scale).round()).toDouble();
    }
  }
  for (final k in _iconDensityKeys) {
    final v = out[k];
    if (v != null) out[k] = math.max(0.02, v * scale);
  }
  return out;
}

ModeOpts scaleRadii(ModeOpts opts, double scale) {
  final out = Map<String, double>.from(opts);
  for (final k in _radiusKeys) {
    final v = out[k];
    if (v != null) out[k] = v * scale;
  }
  // remember the multiplier itself — spacing-derived radii (the morph
  // outline) use it, since they aren't based on any single radius key
  out['rSizeMul'] = (out['rSizeMul'] ?? 1) * scale;
  return out;
}

/// Base (fine) profiles per mode, before preset multipliers.
const Map<String, ModeOpts> baseProfiles = {
  'globe': {
    'latRings': 17,
    'lonDensity': 44,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rBoost': 1.0,
    'inkFar': 0.62,
    'inkSpan': 0.54,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'orbits': {
    'orbitN': 12,
    'ghostN': 40,
    'ghostR': 0.9,
    'ghostA': 0.5,
    'particles': 3,
    'partR': 1.2,
    'partRDepth': 1.6,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'rubik': {
    'latRings': 15,
    'lonDensity': 40,
    'moveCount': 14,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rActive': 0.3,
    'inkFar': 0.62,
    'inkSpan': 0.54,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'wave': {
    'rings': 15,
    'lonDensity': 40,
    'rBase': 0.6,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'ribbon': {
    'lanes': 5,
    'segs': 88,
    'ghostN': 150,
    'rBase': 1.1,
    'rDepth': 1.7,
    'rsPow': 0.6,
    'rMin': 0.3,
  },
  'morph': {
    'rDot': 0.021,
    'iconD': 1,
    'rMin': 0.25,
  },
};
