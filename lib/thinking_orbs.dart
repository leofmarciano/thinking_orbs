/// Dotted thought-orb loading indicators for AI & agent UIs — nine tuned
/// states, two sizes, auto dark/light, and optional custom colors.
///
/// A Dart/Flutter reimplementation of Jakub Antalik's
/// [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs).
library thinking_orbs;

export 'src/thinking_orb.dart' show ThinkingOrb;
export 'src/types.dart' show OrbSize, OrbState, OrbTheme;

// Power-user surface: the resolved presets, raw frame painters and the
// pure-geometry frame builders, for consumers driving their own canvas
// outside the widget.
export 'src/presets.dart' show Resolved, resolvePreset, stateToMode;
export 'src/engine/registry.dart' show modeDraws, modeFrames;
export 'src/engine/types.dart' show Dot, Line, ModeDraw, ModeFrame, OrbFrame;
export 'src/engine/profiles.dart' show ModeOpts;

// Engine escape hatches (the upstream core exports): frame finalization
// and painting plus the shared projector/radius helpers, for consumers
// composing custom frames by hand.
export 'src/engine/core.dart'
    show
        finalizeFrame,
        paintDots,
        paintFrame,
        paintLines,
        makeProj,
        radiusScale,
        Projected,
        Projector;
