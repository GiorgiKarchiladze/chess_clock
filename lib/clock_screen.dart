import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chess_clock.dart';

const _activeColor = Color(0xFF2E7D32);
const _idleColor = Color(0xFF303030);
const _flaggedColor = Color(0xFFC62828);

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key, required this.initialTime});

  final Duration initialTime;

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  late final ChessClock _clock = ChessClock(initialTime: widget.initialTime);
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_clock.isRunning) return;
      setState(_clock.update);
      if (_clock.isFinished) HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _onTap() {
    if (_clock.isFinished) return;
    HapticFeedback.lightImpact();
    setState(_clock.tap);
  }

  void _togglePause() {
    setState(_clock.isPaused ? _clock.resume : _clock.pause);
  }

  /// Pauses and asks for confirmation if a game is in progress.
  Future<bool> _confirm(String title) async {
    if (!_clock.isStarted || _clock.isFinished) return true;
    setState(_clock.pause);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _reset() async {
    if (await _confirm('Restart the game?')) setState(_clock.reset);
  }

  Future<void> _exit() async {
    if (await _confirm('Leave the game?') && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          children: [
            Column(
              children: [
                // Player 2 sits across the table, so their half is upside down.
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 2,
                    child: _PlayerHalf(clock: _clock, player: 1),
                  ),
                ),
                Expanded(child: _PlayerHalf(clock: _clock, player: 0)),
              ],
            ),
            Center(child: _controls()),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Back',
            color: Colors.white,
            icon: const Icon(Icons.close),
            onPressed: _exit,
          ),
          IconButton(
            tooltip: _clock.isPaused ? 'Resume' : 'Pause',
            color: Colors.white,
            icon: Icon(_clock.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _clock.isRunning || _clock.isPaused
                ? _togglePause
                : null,
          ),
          IconButton(
            tooltip: 'Restart',
            color: Colors.white,
            icon: const Icon(Icons.refresh),
            onPressed: _clock.isStarted ? _reset : null,
          ),
        ],
      ),
    );
  }
}

class _PlayerHalf extends StatelessWidget {
  const _PlayerHalf({required this.clock, required this.player});

  final ChessClock clock;
  final int player;

  @override
  Widget build(BuildContext context) {
    final flagged = clock.flaggedPlayer == player;
    final active = clock.activePlayer == player && !clock.isFinished;
    final color = flagged
        ? _flaggedColor
        : active
        ? _activeColor
        : _idleColor;

    final String status;
    if (flagged) {
      status = "Time's up";
    } else if (!clock.isStarted) {
      status = player == 0 ? 'Tap anywhere to start' : '';
    } else if (active && clock.isPaused) {
      status = 'Paused';
    } else {
      status = 'Moves: ${clock.moves(player)}';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: color,
      width: double.infinity,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                _format(clock.remaining(player)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 96,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// m:ss, switching to m:ss.t under ten seconds.
String _format(Duration d) {
  final minutes = d.inMinutes;
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d < const Duration(seconds: 10)) {
    final tenths = (d.inMilliseconds % 1000) ~/ 100;
    return '$minutes:$seconds.$tenths';
  }
  return '$minutes:$seconds';
}
