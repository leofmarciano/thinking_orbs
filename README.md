# thinking_orbs (Flutter)

> A faithful Dart/Flutter reimplementation of
> [**thinking-orbs**](https://github.com/Jakubantalik/thinking-orbs) by
> [Jakub Antalik](https://github.com/Jakubantalik) — originally a React +
> 2D-canvas library. This port recreates the entire module end to end
> (engine math, presets, and all six animations, copied 1:1) so it can be
> used in Flutter mobile apps. All animation design credit goes to the
> original author. Original live demo: <https://orbs.jakubantalik.com>.

Dotted thought-orb loading indicators for AI & agent UIs. Six hand-tuned
animated states, each shipped at two purpose-tuned sizes, rendered with a
plain `CustomPainter` — no shaders, no filters, identical pixels on iOS,
Android, web and desktop.

## Install

Not published on pub.dev — install directly from a
[GitHub release tag](https://github.com/leofmarciano/thinking_orbs/releases).
Add to your `pubspec.yaml`, pinning `ref` to a released tag for a
reproducible build:

```yaml
dependencies:
  thinking_orbs:
    git:
      url: https://github.com/leofmarciano/thinking_orbs.git
      ref: v0.1.0 # pin to a release tag; omit to track main
```

Then run `flutter pub get`.

## Quick start

```dart
import 'package:thinking_orbs/thinking_orbs.dart';

Widget status() {
  return const ThinkingOrb(state: OrbState.searching, size: OrbSize.size64);
}
```

## States

Six verbs an agent can be doing, each a distinct animation:

```dart
ThinkingOrb(state: OrbState.working)    // particles on tilted orbits
ThinkingOrb(state: OrbState.searching)  // a scan meridian sweeps a dotted globe
ThinkingOrb(state: OrbState.solving)    // bands scramble, then click back solved
ThinkingOrb(state: OrbState.listening)  // a waveform rolls through the rings
ThinkingOrb(state: OrbState.composing)  // an undulating multi-band sash
ThinkingOrb(state: OrbState.shaping)    // dotted outline: circle → triangle → square
```

## Sizes

Two tuned presets — separate designs, not a scale factor. `OrbSize.size64`
for chat-avatar scale, `OrbSize.size20` for inline-text scale. Each carries
its own dot count, dot size and speed tuning:

```dart
ThinkingOrb(state: OrbState.working, size: OrbSize.size64)
ThinkingOrb(state: OrbState.working, size: OrbSize.size20)
```

## Theme

Strictly monochrome — light ink for dark backgrounds, dark ink for light
backgrounds:

```dart
ThinkingOrb(theme: OrbTheme.auto)   // default — follows the platform brightness
ThinkingOrb(theme: OrbTheme.dark)   // pin: light dots for dark backgrounds
ThinkingOrb(theme: OrbTheme.light)  // pin: dark dots for light backgrounds
```

`OrbTheme.auto` follows `MediaQuery.platformBrightness` (the OS setting,
live-updating — the analogue of the original's `prefers-color-scheme`).
Apps that drive their own light/dark theme independently of the OS should
pin `OrbTheme.dark` / `OrbTheme.light` from their theme state.

## Other props

```dart
ThinkingOrb(
  state: OrbState.solving,
  size: OrbSize.size20,
  speed: 1.5,                              // multiplier on the preset's baked speed
  paused: false,                           // freeze on the current frame
  semanticLabel: 'Analysing repository…',  // overrides the per-state default
)
```

## Accessibility & performance

- `Semantics(image: true)` with a sensible per-state label out of the box.
- When animations are disabled (`MediaQuery.disableAnimations` — e.g. iOS
  Reduce Motion / Android "remove animations") a static representative
  frame is rendered — no animation — and it still follows the live theme.
- Every instance pauses automatically when its subtree's `TickerMode` is
  disabled (navigated-away routes, backgrounded app), and resumes in
  phase — all instances share one clock.
- Plain circle fills only: no shaders, no blur filters — cheap on low-end
  devices. Repaints are driven through a `ValueNotifier`, so animation
  frames never rebuild the widget tree.
- Unlike the browser original there is no automatic offscreen-scroll
  pause (Flutter has no IntersectionObserver); lists that recycle their
  children (`ListView.builder`) dispose offscreen orbs, which achieves
  the same effect.

## Power-user surface

The resolved presets and raw frame painters are exported for consumers
driving their own canvas:

```dart
final resolved = resolvePreset(OrbState.searching, OrbSize.size64);
final draw = modeDraws[resolved.mode]!;
// draw(canvas, size, t * resolved.speed, dark, resolved.opts);
```

## Example

The [example](example/) app is a playground showing all six states at both
sizes with theme toggle, speed slider and play/pause:

```bash
cd example && flutter run
```

## License

MIT — original design and animations © Jakub Antalik
([thinking-orbs](https://github.com/Jakubantalik/thinking-orbs)); Dart/Flutter
port © [Leonardo Marciano](https://github.com/leofmarciano).
