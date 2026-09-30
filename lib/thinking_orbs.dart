/// Dotted thought-orb loading indicators for AI & agent UIs — six tuned
/// states, two sizes, auto dark/light, and optional custom colors.
///
/// A Dart/Flutter reimplementation of Jakub Antalik's
/// [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs).
library thinking_orbs;

export 'src/thinking_orb.dart' show ThinkingOrb;
export 'src/types.dart' show OrbSize, OrbState, OrbTheme;

// Power-user surface: the resolved presets + raw frame painters, for
// consumers driving their own canvas outside the widget.
export 'src/presets.dart' show Resolved, resolvePreset, stateToMode;
export 'src/engine/registry.dart' show modeDraws;
export 'src/engine/types.dart' show ModeDraw;
export 'src/engine/profiles.dart' show ModeOpts;
