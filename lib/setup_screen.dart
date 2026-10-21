import 'package:flutter/material.dart';

import 'clock_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const _options = [5, 10];
  int _minutes = 5;

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClockScreen(initialTime: Duration(minutes: _minutes)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('Chess Clock', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 32),
                Text('Time per player', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: [
                    for (final m in _options)
                      ButtonSegment(value: m, label: Text('$m min')),
                  ],
                  selected: {_minutes},
                  onSelectionChanged: (s) => setState(() => _minutes = s.first),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _start,
                    child: const Text('Start', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
