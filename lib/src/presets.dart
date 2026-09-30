// The shipped tunings: nine states × two sizes, baked from the original
// inkform mini-page tuning session. `count`/`size` are multipliers over
// the base fine profiles; `speed` multiplies the shared clock. Resolved
// once per (state, size) pair and cached — the render loop sees plain
// numbers.

import 'engine/profiles.dart';
import 'types.dart';

/// Map from public state to internal draw-mode key.
const Map<OrbState, String> stateToMode = {
  OrbState.working: 'orbits',
  OrbState.searching: 'globe',
  OrbState.solving: 'rubik',
  OrbState.listening: 'wave',
  OrbState.connecting: 'web',
  OrbState.weaving: 'braid',
  OrbState.composing: 'ribbon',
  OrbState.breathing: 'ring',
  OrbState.shaping: 'morph',
};

class _Preset {
  const _Preset(
      {required this.speed,
      required this.count,
      required this.size,
      this.extra});

  final double speed;
  final double count;
  final double size;

  /// Extra mode opts merged verbatim after scaling.
  final ModeOpts? extra;
}

const Map<String, Map<OrbSize, _Preset>> _presets = {
  'orbits': {
    OrbSize.size64: _Preset(speed: 1.885, count: 1, size: 1),
    OrbSize.size20: _Preset(speed: 3.9, count: 0.238, size: 2.4),
  },
  'globe': {
    OrbSize.size64: _Preset(
      speed: 2.015,
      count: 0.42,
      size: 1.15,
      extra: {'scanMul': 4.08, 'dimBase': 0.45},
    ),
    OrbSize.size20: _Preset(
      speed: 2.665,
      count: 0.105,
      size: 1.75,
      extra: {'scanMul': 4.335, 'dimBase': 0.45},
    ),
  },
  'rubik': {
    OrbSize.size64: _Preset(speed: 1.82, count: 0.35, size: 1.05),
    OrbSize.size20: _Preset(speed: 1.95, count: 0.088, size: 1.9),
  },
  'wave': {
    OrbSize.size64: _Preset(speed: 4.388, count: 0.341, size: 1),
    OrbSize.size20: _Preset(speed: 3.998, count: 0.105, size: 1.6),
  },
  'web': {
    OrbSize.size64: _Preset(speed: 3.315, count: 1.35, size: 0.95),
    OrbSize.size20: _Preset(speed: 6.63, count: 0.25, size: 1.52),
  },
  'braid': {
    OrbSize.size64: _Preset(speed: 1.625, count: 0.5, size: 1),
    OrbSize.size20: _Preset(speed: 2.75, count: 0.1125, size: 1.36),
  },
  'ribbon': {
    OrbSize.size64: _Preset(
      speed: 2.34,
      count: 0.25,
      size: 0.85,
      extra: {'spin': 0, 'bandMul': 3.9, 'wobMul': 1},
    ),
    OrbSize.size20: _Preset(
      speed: 3.12,
      count: 0.051,
      size: 1.073,
      extra: {'spin': 0, 'bandMul': 4.94, 'wobMul': 1},
    ),
  },
  'ring': {
    OrbSize.size64: _Preset(
      speed: 3.24,
      count: 0.25,
      size: 0.956,
      extra: {'spin': 0, 'bandMul': 3.627, 'wobMul': 0.368},
    ),
    OrbSize.size20: _Preset(
      speed: 3.78,
      count: 0.028,
      size: 1.622,
      extra: {'spin': 0, 'bandMul': 3.968, 'wobMul': 0.565},
    ),
  },
  'morph': {
    OrbSize.size64: _Preset(
        speed: 2.405, count: 0.702, size: 0.395, extra: {'spread': 1.45}),
    OrbSize.size20:
        _Preset(speed: 2.08, count: 0.53, size: 1.011, extra: {'spread': 1.45}),
  },
};

/// A (state, size) pair resolved to its mode key, clock speed and
/// fully-scaled draw options.
class Resolved {
  const Resolved({required this.mode, required this.speed, required this.opts});

  final String mode;
  final double speed;
  final ModeOpts opts;
}

final Map<String, Resolved> _cache = {};

/// Resolve a (state, size) pair to its mode + fully-scaled draw options.
Resolved resolvePreset(OrbState state, OrbSize size) {
  final key = '${state.name}-${size.name}';
  final hit = _cache[key];
  if (hit != null) return hit;

  final mode = stateToMode[state]!;
  final preset = _presets[mode]![size]!;
  var opts = Map<String, double>.from(baseProfiles[mode]!);
  if (preset.count != 1) opts = scaleCounts(opts, preset.count);
  if (preset.size != 1) opts = scaleRadii(opts, preset.size);
  final extra = preset.extra;
  if (extra != null) opts = {...opts, ...extra};

  final resolved = Resolved(mode: mode, speed: preset.speed, opts: opts);
  _cache[key] = resolved;
  return resolved;
}
