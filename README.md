# thinking_orbs for Flutter

[![pub package](https://img.shields.io/pub/v/thinking_orbs.svg)](https://pub.dev/packages/thinking_orbs)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

![All nine orb states animating on a dark background](https://raw.githubusercontent.com/leofmarciano/thinking_orbs/main/doc/preview.gif)

Dotted thought-orb loading indicators for AI and agent interfaces. The package
ships nine hand-tuned animations at two purpose-built sizes, rendered with a
lightweight Flutter `CustomPainter` on a transparent background.

This is a faithful Dart/Flutter reimplementation of
[Jakub Antalik's thinking-orbs](https://github.com/Jakubantalik/thinking-orbs),
originally built for React and the browser 2D canvas. The Flutter engine and
initial package were created by
[Leonardo Marciano](https://github.com/leofmarciano). See
[Credits and provenance](#credits-and-provenance) for the complete attribution.

## Highlights

- Nine distinct states: working, searching, solving, listening, connecting,
  weaving, composing, breathing, and shaping.
- Separate 64 px and 20 px tunings; the inline orb is not merely a scaled-down
  copy.
- Automatic light/dark monochrome rendering plus optional custom colors.
- Adjustable speed and a pause control.
- Built-in semantic labels and reduced-motion support.
- One shared clock keeps multiple orbs in phase without rebuilding the widget
  tree every frame.
- No assets, shaders, platform channels, or native configuration.
- Runs on Android, iOS, web, macOS, Windows, and Linux.

## Installation

Install the latest published release from
[pub.dev](https://pub.dev/packages/thinking_orbs):

```bash
flutter pub add thinking_orbs
```

Or add it manually:

```yaml
dependencies:
  thinking_orbs: ^0.2.0
```

Then import the package:

```dart
import 'package:thinking_orbs/thinking_orbs.dart';
```

## Quick start

```dart
const ThinkingOrb(
  state: OrbState.searching,
  size: OrbSize.size64,
  semanticLabel: 'Searching documentation…',
)
```

The canvas is transparent, so the widget can be placed directly in a chat
avatar, status row, button, card, or overlay.

## Animation states

| State | Visual behavior | Typical use |
| --- | --- | --- |
| `OrbState.working` | Particles travel across tilted orbital paths | General processing |
| `OrbState.searching` | A scan meridian sweeps a dotted globe | Search and retrieval |
| `OrbState.solving` | Bands scramble and click back into place | Reasoning and solving |
| `OrbState.listening` | A waveform rolls through latitude rings | Voice and audio input |
| `OrbState.connecting` | A constellation of nodes wires itself with travelling signal packets | Handshakes and tool calls |
| `OrbState.weaving` | Three strands plait around a ghost sphere | Combining sources or ideas |
| `OrbState.composing` | An undulating multi-band ribbon | Writing and generation |
| `OrbState.breathing` | A face-on ring slowly pulses | Idle thinking |
| `OrbState.shaping` | Circle → triangle → square outline morph | Structuring and design |

```dart
const ThinkingOrb(state: OrbState.working);
const ThinkingOrb(state: OrbState.searching);
const ThinkingOrb(state: OrbState.solving);
const ThinkingOrb(state: OrbState.listening);
const ThinkingOrb(state: OrbState.connecting);
const ThinkingOrb(state: OrbState.weaving);
const ThinkingOrb(state: OrbState.composing);
const ThinkingOrb(state: OrbState.breathing);
const ThinkingOrb(state: OrbState.shaping);
```

## Sizes

The package intentionally exposes two presets:

```dart
const ThinkingOrb(size: OrbSize.size64); // chat-avatar scale
const ThinkingOrb(size: OrbSize.size20); // inline-text scale
```

Each preset has its own dot count, radius, density, and speed tuning. Wrap an
orb in padding or a larger layout container instead of scaling the painter when
you need a larger touch or visual area.

## Custom colors

Pass any Flutter `Color` to tint the orb:

```dart
const ThinkingOrb(
  state: OrbState.composing,
  color: Color(0xFF8B5CF6),
)
```

The supplied hue is not applied as a flat overlay. The renderer converts the
original near/far ink strength into opacity, preserving depth shading and the
intentional fades used by ghost paths and background dots. The color's own
alpha channel is respected as well.

When `color` is non-null it takes precedence over `theme`. Set it back to null
to restore the original monochrome palette:

```dart
ThinkingOrb(
  color: useBrandColor ? brandColor : null,
  theme: OrbTheme.auto,
)
```

Choose a color with enough contrast against the surface behind the transparent
orb. The package deliberately does not guess or modify your brand color.

## Monochrome themes

Without a custom color, the original monochrome renderer follows the platform
brightness or a pinned theme:

```dart
const ThinkingOrb(theme: OrbTheme.auto);  // follows platform brightness
const ThinkingOrb(theme: OrbTheme.dark);  // light ink on dark surfaces
const ThinkingOrb(theme: OrbTheme.light); // dark ink on light surfaces
```

`OrbTheme.auto` follows `MediaQuery.platformBrightness` and updates when the
platform setting changes. Apps whose theme is independent of the OS should pass
`OrbTheme.dark` or `OrbTheme.light` from their own theme state.

## Complete widget API

```dart
ThinkingOrb(
  state: OrbState.solving,
  size: OrbSize.size20,
  theme: OrbTheme.auto,
  color: const Color(0xFF38BDF8),
  speed: 1.5,
  paused: false,
  semanticLabel: 'Analysing repository…',
)
```

| Property | Default | Description |
| --- | --- | --- |
| `state` | `OrbState.working` | Selects one of the nine animation modes |
| `size` | `OrbSize.size64` | Selects the tuned 64 px or 20 px preset |
| `theme` | `OrbTheme.auto` | Controls the monochrome palette |
| `color` | `null` | Overrides the monochrome palette with a custom hue |
| `speed` | `1.0` | Multiplies the preset's baked animation speed |
| `paused` | `false` | Freezes the current frame |
| `semanticLabel` | Per-state label | Overrides the accessibility description |

## Accessibility and lifecycle

- The widget exposes `Semantics(image: true)` and a useful per-state label.
- `MediaQuery.disableAnimations` renders a deterministic static frame for users
  who request reduced motion.
- `TickerMode` automatically mutes animation for inactive routes and
  backgrounded widget subtrees.
- Consumers rendering long lists should use lazy builders so offscreen orbs are
  disposed normally.

## Performance

All modes draw ordinary circles on a Flutter `Canvas`. There are no image
assets, blur filters, fragment shaders, or WebGL dependencies. Animation frames
are delivered to `CustomPainter` through a `ValueNotifier`, so the surrounding
widget tree is not rebuilt on every tick.

The renderer retains the original project's deterministic geometry, z sorting,
depth-aware radius, and hand-tuned density profiles.

## Geometry and painter API

For consumers that own their canvas, animation clock, or renderer, the engine
is exposed in two layers. `resolvePreset` maps a public `(state, size)` pair
to its internal mode key, clock speed, and fully-scaled options:

```dart
final resolved = resolvePreset(OrbState.searching, OrbSize.size64);
// resolved.mode — engine key ('globe'), also reachable via stateToMode
// resolved.speed — clock multiplier for this preset
// resolved.opts  — ModeOpts (Map<String, double>) for the frame builders
```

**`modeFrames`** is the pure-geometry layer: a `Map<String, ModeFrame>` of
`OrbFrame Function(double size, double t, ModeOpts opts)` builders with no
`Canvas` dependency. A frame is a finished set of draw instructions —
`frame.dots` is already z-sorted far→near and radius-clamped, and
`frame.lines` (edges, e.g. the `connecting` web) paints first:

```dart
final frame = modeFrames[resolved.mode]!(
  64,                            // logical size in px
  elapsedSeconds * resolved.speed,
  resolved.opts,
);

for (final line in frame.lines) {
  // line.x1, line.y1 → line.x2, line.y2 — endpoints;
  // line.w — stroke width; line.white / line.a — ink strength and alpha
}
for (final dot in frame.dots) {
  // dot.x, dot.y — position; dot.r — radius;
  // dot.white — ink strength (mirrored on dark themes); dot.a — extra alpha
}
```

This layer is what the golden-vector parity tests compare numerically against
the upstream TypeScript engine, so its output is a stable, renderer-agnostic
contract.

**`modeDraws`** is the matching `Map<String, ModeDraw>` of `Canvas` painters
built on top of `modeFrames` — the same functions the widget calls:

```dart
final draw = modeDraws[resolved.mode]!;

draw(
  canvas,
  64,
  elapsedSeconds * resolved.speed,
  true, // dark palette
  resolved.opts,
  const Color(0xFF34D399), // optional custom color
);
```

The custom color is an optional sixth argument; five-argument painter calls
remain valid.

The engine's shared helpers are exported as well for consumers composing
custom frames by hand: `finalizeFrame` (cull, radius-clamp, z-sort raw
geometry into an `OrbFrame`), `paintFrame`/`paintDots`/`paintLines` (the
ink-to-canvas passes), `makeProj` (the shared yaw/tilt projector returning a
`Projected` triple via a `Projector`), and `radiusScale` (the sub-linear dot
radius scaling).

All frame builders accept any finite `t` — negative values render the
animation's periodic extension rather than throwing — and tolerate degenerate
or non-integer counts.

## Example playground

The [`example`](example/) app shows every state at both sizes and includes live
controls for speed, pause/play, light/dark mode, and color. Its grid adapts to
the available width rather than assuming a device type.

```bash
cd example
flutter run
```

Run it in a browser with:

```bash
flutter run -d chrome
```

## Development and verification

```bash
flutter pub get
flutter analyze
flutter test   # includes parity_test.dart against upstream golden vectors

cd example
flutter test
flutter build web
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the release workflow.

## Credits and provenance

- Original animation design and TypeScript/Canvas implementation:
  [Jakub Antalik](https://github.com/Jakubantalik),
  [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs).
- Dart/Flutter engine and initial package:
  [Leonardo Marciano](https://github.com/leofmarciano),
  [thinking_orbs](https://github.com/leofmarciano/thinking_orbs).
- Custom-color support, responsive playground, tests, and documentation:
  [nathankim0](https://github.com/nathankim0).
- Subsequent improvements are documented in the repository history and pull
  requests.

This project preserves the original MIT license notice. A community port is not
an official endorsement by the original author unless they explicitly say so.

## License

MIT. See [LICENSE](LICENSE) for the complete notices and terms.
