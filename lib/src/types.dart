// Public value types for the ThinkingOrb widget.

/// The six shipped states — each a hand-tuned animation:
/// - [working]   — particles on tilted orbits
/// - [searching] — a scan meridian sweeps a dotted globe
/// - [solving]   — bands scramble in quarter turns, then click back
/// - [listening] — a waveform rolls through latitude rings
/// - [composing] — an undulating multi-band sash
/// - [shaping]   — a dotted outline morphs circle → triangle → square
enum OrbState { working, searching, solving, listening, composing, shaping }

/// Rendered size in logical pixels. Exactly two tuned presets ship:
/// [size64] (chat-avatar scale) and [size20] (inline-text scale). Each
/// size carries its own dot count, dot size and speed tuning — they are
/// separate designs, not a scale factor.
enum OrbSize {
  size64(64),
  size20(20);

  const OrbSize(this.px);

  /// The rendered edge length in logical pixels.
  final double px;
}

/// Theme mode.
///
/// - [auto] (default) resolves from the enclosing [Theme] / [MediaQuery]
///   brightness, live-updating on change.
/// - [dark] / [light] pin the palette regardless of context.
///
/// Dark renders light ink on the transparent canvas (for dark
/// backgrounds); light renders dark ink (for light backgrounds).
enum OrbTheme { auto, dark, light }
