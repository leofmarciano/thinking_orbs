// Playground for the thinking_orbs package — mirrors the original
// thinking-orbs demo: all nine states at both tuned sizes, with theme
// toggle, custom colors, speed slider and play/pause.

import 'package:flutter/material.dart';
import 'package:thinking_orbs/thinking_orbs.dart';

void main() {
  runApp(const OrbsPlaygroundApp());
}

class OrbsPlaygroundApp extends StatefulWidget {
  const OrbsPlaygroundApp({super.key});

  @override
  State<OrbsPlaygroundApp> createState() => _OrbsPlaygroundAppState();
}

class _OrbsPlaygroundAppState extends State<OrbsPlaygroundApp> {
  bool _dark = true;
  double _speed = 1;
  bool _paused = false;
  Color? _color = const Color(0xFF8B5CF6);

  static const _labels = {
    OrbState.working: 'working',
    OrbState.searching: 'searching',
    OrbState.solving: 'solving',
    OrbState.listening: 'listening',
    OrbState.connecting: 'connecting',
    OrbState.weaving: 'weaving',
    OrbState.composing: 'composing',
    OrbState.breathing: 'breathing',
    OrbState.shaping: 'shaping',
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'thinking_orbs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            _dark ? const Color(0xFF09090B) : const Color(0xFFFAFAFA),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('thinking_orbs'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: _paused ? 'Play' : 'Pause',
              icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              onPressed: () => setState(() => _paused = !_paused),
            ),
            IconButton(
              tooltip: _dark ? 'Light mode' : 'Dark mode',
              icon: Icon(_dark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _dark = !_dark),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth < 600 ? 16.0 : 24.0;
              return Column(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: LayoutBuilder(
                          builder: (context, controlConstraints) {
                            final compact = controlConstraints.maxWidth < 720;
                            final speedControl = Row(
                              children: [
                                const Text('speed'),
                                Expanded(
                                  child: Slider(
                                    value: _speed,
                                    min: 0.25,
                                    max: 3,
                                    divisions: 11,
                                    label: '${_speed.toStringAsFixed(2)}x',
                                    onChanged: (v) =>
                                        setState(() => _speed = v),
                                  ),
                                ),
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    '${_speed.toStringAsFixed(2)}x',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            );
                            final colorPicker = _ColorPicker(
                              selected: _color,
                              onSelected: (color) =>
                                  setState(() => _color = color),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  speedControl,
                                  const SizedBox(height: 4),
                                  colorPicker,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: speedControl),
                                const SizedBox(width: 32),
                                colorPicker,
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1120),
                        child: GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            16,
                            horizontalPadding,
                            24,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 220,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: OrbState.values.length,
                          itemBuilder: (context, index) {
                            final state = OrbState.values[index];
                            return _OrbCard(
                              key: ValueKey('orb-card-${state.name}'),
                              state: state,
                              label: _labels[state]!,
                              theme: _dark ? OrbTheme.dark : OrbTheme.light,
                              color: _color,
                              speed: _speed,
                              paused: _paused,
                              dark: _dark,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});

  static const options = <({String key, String label, Color? color})>[
    (key: 'original', label: 'Original monochrome', color: null),
    (key: 'violet', label: 'Violet', color: Color(0xFF8B5CF6)),
    (key: 'sky', label: 'Sky blue', color: Color(0xFF38BDF8)),
    (key: 'emerald', label: 'Emerald', color: Color(0xFF34D399)),
    (key: 'amber', label: 'Amber', color: Color(0xFFF59E0B)),
  ];

  final Color? selected;
  final ValueChanged<Color?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('color'),
        const SizedBox(width: 8),
        for (final option in options)
          SizedBox.square(
            dimension: 44,
            child: Tooltip(
              message: option.label,
              child: Semantics(
                button: true,
                selected: option.color == selected,
                label: option.label,
                child: InkWell(
                  key: ValueKey('color-${option.key}'),
                  customBorder: const CircleBorder(),
                  onTap: () => onSelected(option.color),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: option.color == selected ? 28 : 24,
                      height: option.color == selected ? 28 : 24,
                      decoration: BoxDecoration(
                        color: option.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: option.color == selected
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outline,
                          width: option.color == selected ? 2 : 1,
                        ),
                      ),
                      child: option.color == null
                          ? const Icon(Icons.contrast, size: 16)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OrbCard extends StatelessWidget {
  const _OrbCard({
    super.key,
    required this.state,
    required this.label,
    required this.theme,
    required this.color,
    required this.speed,
    required this.paused,
    required this.dark,
  });

  final OrbState state;
  final String label;
  final OrbTheme theme;
  final Color? color;
  final double speed;
  final bool paused;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ThinkingOrb(
                state: state,
                size: OrbSize.size64,
                theme: theme,
                color: color,
                speed: speed,
                paused: paused,
              ),
              const SizedBox(width: 20),
              ThinkingOrb(
                state: state,
                size: OrbSize.size20,
                theme: theme,
                color: color,
                speed: speed,
                paused: paused,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: dark ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
            ),
          ),
        ],
      ),
    );
  }
}
