// The ThinkingOrb widget. One shared clock keeps every mounted orb in
// phase; each instance runs its own Ticker but pauses automatically when
// its TickerMode is disabled (hidden routes, backgrounded app — the
// Flutter analogue of the original's visibilitychange handling).
// Reduced-motion users get a static representative frame that still
// follows the live theme.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'engine/registry.dart';
import 'engine/types.dart';
import 'presets.dart';
import 'types.dart';

const Map<OrbState, String> _labels = {
  OrbState.working: 'Working…',
  OrbState.searching: 'Searching…',
  OrbState.solving: 'Solving…',
  OrbState.listening: 'Listening…',
  OrbState.composing: 'Composing…',
  OrbState.shaping: 'Shaping…',
};

/// One global epoch shared by every orb instance — the analogue of the
/// original's shared `performance.now()` clock. All orbs sample the same
/// timeline, so multiple instances stay in phase.
final Stopwatch _sharedClock = Stopwatch()..start();

double _nowSeconds() => _sharedClock.elapsedMicroseconds / 1e6;

/// Dotted thought-orb loading indicator for AI & agent UIs.
///
/// A Dart/Flutter reimplementation of Jakub Antalik's
/// [thinking-orbs](https://github.com/Jakubantalik/thinking-orbs).
class ThinkingOrb extends StatefulWidget {
  const ThinkingOrb({
    super.key,
    this.state = OrbState.working,
    this.size = OrbSize.size64,
    this.theme = OrbTheme.auto,
    this.color,
    this.speed = 1,
    this.paused = false,
    this.semanticLabel,
  });

  /// Which animation to show. Defaults to [OrbState.working].
  final OrbState state;

  /// Tuned size preset — 64 or 20 logical px. Defaults to [OrbSize.size64].
  final OrbSize size;

  /// Monochrome theme mode; [OrbTheme.auto] follows platform brightness.
  /// Ignored when [color] is non-null.
  final OrbTheme theme;

  /// Optional foreground color for the dots.
  ///
  /// When set, this color takes precedence over [theme]. Depth shading is
  /// preserved by varying the dots' opacity instead of flattening them to a
  /// single solid color.
  final Color? color;

  /// Animation speed multiplier on top of the preset's baked speed.
  final double speed;

  /// Freeze the animation on the current frame.
  final bool paused;

  /// Overrides the per-state default semantic label.
  final String? semanticLabel;

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Current animation time (already multiplied by the effective speed),
  /// pushed to the painter without rebuilding the widget tree.
  late final ValueNotifier<double> _t;

  late Resolved _resolved;
  double _effSpeed = 1;

  @override
  void initState() {
    super.initState();
    _resolve();
    _t = ValueNotifier<double>(_nowSeconds() * _effSpeed);
    _ticker = createTicker(_onTick);
    _syncTicker(reduced: false);
  }

  void _resolve() {
    _resolved = resolvePreset(widget.state, widget.size);
    _effSpeed = _resolved.speed * widget.speed;
  }

  void _onTick(Duration _) {
    _t.value = _nowSeconds() * _effSpeed;
  }

  bool _reducedMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  bool _resolveDark(BuildContext context) {
    switch (widget.theme) {
      case OrbTheme.dark:
        return true;
      case OrbTheme.light:
        return false;
      case OrbTheme.auto:
        // Nearest inherited brightness; the pre-resolution fallback is
        // dark, matching the original.
        final brightness = _ambientBrightness(context);
        return (brightness ?? Brightness.dark) == Brightness.dark;
    }
  }

  Brightness? _ambientBrightness(BuildContext context) {
    // MediaQuery.platformBrightness follows the OS setting live —
    // the analogue of prefers-color-scheme. Apps that drive their own
    // theme should pin OrbTheme.dark/light or wrap in a MediaQuery.
    return MediaQuery.maybePlatformBrightnessOf(context);
  }

  void _syncTicker({required bool reduced}) {
    final shouldRun = !widget.paused && !reduced;
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didUpdateWidget(ThinkingOrb old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state ||
        old.size != widget.size ||
        old.speed != widget.speed) {
      _resolve();
      _t.value = _nowSeconds() * _effSpeed;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reducedMotion(context);
    final dark = _resolveDark(context);
    _syncTicker(reduced: reduced);

    final size = widget.size.px;
    return Semantics(
      label: widget.semanticLabel ?? _labels[widget.state],
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _OrbPainter(
              t: _t,
              // reduced motion → one static, deterministic frame
              staticT: reduced ? 0.6 : null,
              size: size,
              dark: dark,
              color: widget.color,
              draw: modeDraws[_resolved.mode]!,
              opts: _resolved.opts,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required ValueNotifier<double> t,
    required this.staticT,
    required this.size,
    required this.dark,
    required this.color,
    required this.draw,
    required this.opts,
  })  : _t = t,
        super(repaint: staticT == null ? t : null);

  final ValueNotifier<double> _t;
  final double? staticT;
  final double size;
  final bool dark;
  final Color? color;
  final ModeDraw draw;
  final Map<String, double> opts;

  @override
  void paint(Canvas canvas, Size _) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size, size));
    draw(canvas, size, staticT ?? _t.value, dark, opts, color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrbPainter old) {
    return old.dark != dark ||
        old.color != color ||
        old.draw != draw ||
        old.opts != opts ||
        old.staticT != staticT ||
        old.size != size;
  }
}
