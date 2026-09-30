# thinking_orbs for Flutter

[![pub package](https://img.shields.io/pub/v/thinking_orbs.svg)](https://pub.dev/packages/thinking_orbs)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Dotted thought-orb loading indicators for AI and agent interfaces. The package
ships six hand-tuned animations at two purpose-built sizes, rendered with a
lightweight Flutter `CustomPainter` on a transparent background.

This is a faithful Dart/Flutter reimplementation of
[Jakub Antalik's thinking-orbs](https://github.com/Jakubantalik/thinking-orbs),
originally built for React and the browser 2D canvas. The Flutter engine and
initial package were created by
[Leonardo Marciano](https://github.com/leofmarciano). See
[Credits and provenance](#credits-and-provenance) for the complete attribution.

## Highlights

- Six distinct states: working, searching, solving, listening, composing, and
  shaping.
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
  thinking_orbs: ^0.1.0
```

Then import the package:

```dart
import 'package:thinking_orbs/thinking_orbs.dart';
```

> Custom `color` support is currently available on this development branch and
> is intended for the next pub.dev release.

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
| `OrbState.composing` | An undulating multi-band ribbon | Writing and generation |
| `OrbState.shaping` | Circle → triangle → square outline morph | Structuring and design |

```dart
const ThinkingOrb(state: OrbState.working);
const ThinkingOrb(state: OrbState.searching);
const ThinkingOrb(state: OrbState.solving);
const ThinkingOrb(state: OrbState.listening);
const ThinkingOrb(state: OrbState.composing);
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
| `state` | `OrbState.working` | Selects one of the six animation modes |
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

## Power-user painter API

Preset resolution and raw frame painters are exported for consumers that own
their canvas or animation clock:

```dart
final resolved = resolvePreset(OrbState.searching, OrbSize.size64);
final draw = modeDraws[resolved.mode]!;

draw(
  canvas,
  64,
  timeInSeconds * resolved.speed,
  true,
  resolved.opts,
  const Color(0xFF34D399), // optional
);
```

Existing five-argument painter calls remain valid; the custom color is an
optional sixth argument.

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
flutter test

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
