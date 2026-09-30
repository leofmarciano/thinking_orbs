# Changelog

## 0.2.0

Tracks upstream [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs)
v0.3.1.

### Breaking

- `OrbState` gained three members (`connecting`, `weaving`, `breathing`).
  New enum members are source-breaking for exhaustive `switch`
  statements without a `default` branch — add cases for the new members
  or a `default` when upgrading.

### Added

- Three new states — `connecting` (web), `weaving` (braid) and
  `breathing` (ring) — for nine states total, ported from upstream
  thinking-orbs v0.3.1.
- Public geometry API: the paint engine is split into pure-geometry
  frame builders (`modeFrames`, `ModeFrame`, `OrbFrame`, `Dot`, `Line`)
  and canvas painters (`modeDraws`, `ModeDraw`), so consumers can drive
  their own renderer or verify frames numerically.
- Engine helpers for consumers composing custom frames by hand:
  `finalizeFrame`, `paintFrame`, `paintLines`, `paintDots`, `makeProj`,
  `radiusScale`, and the `Projected`/`Projector` types.
- Engine robustness: every mode tolerates negative `t` and degenerate or
  non-integer counts without throwing — inputs that crash upstream render
  the animation's periodic extension or a no-op frame instead.
- Optional custom dot colors that preserve depth through opacity.
- Golden-vector parity tests against upstream frozen frames.
- Example playground: live color palette.
- Widget coverage for compact/wide layouts and interactive controls.

### Changed

- Retune the morph 64 px density 0.54 → 0.702 to match upstream.
- Make the example playground responsive instead of assuming a device
  type.
- Replace generated example and web metadata with project
  documentation.

### Fixed

- `scaleCounts` keeps an explicit zero at zero, so modes that opt out of
  a layer (the ring's missing ghost sphere) stay opted out.
- Correct the original project's copyright year in the license notice.

### Internal

- Validated the automated `pub.dev` publishing pipeline via GitHub
  Actions OIDC (previously staged as 0.1.1, never published).

## 0.1.0

- Initial release: full Dart/Flutter port of
  [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs) v0.1.1.
- Six animated states (`working`, `searching`, `solving`, `listening`,
  `composing`, `shaping`) at two tuned sizes (64 and 20 logical px).
- Auto dark/light theme resolution, shared animation clock, reduced-motion
  static frame, semantic labels.
