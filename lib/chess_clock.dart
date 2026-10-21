/// Returns a monotonically increasing time. Injectable so tests can control it.
typedef TimeSource = Duration Function();

TimeSource _stopwatchSource() {
  final stopwatch = Stopwatch()..start();
  return () => stopwatch.elapsed;
}

/// Pure chess-clock logic for two players (0 and 1), independent of the UI.
class ChessClock {
  ChessClock({required this.initialTime, TimeSource? now})
    : _now = now ?? _stopwatchSource(),
      _stored = [initialTime, initialTime];

  final Duration initialTime;
  final TimeSource _now;

  // Time left for each player as of the start of the current turn.
  final List<Duration> _stored;
  final List<int> _moves = [0, 0];
  int? _active;
  Duration _turnStartedAt = Duration.zero;
  bool _paused = false;
  int? _flagged;

  /// The player whose clock is running (or would be, if paused). Null before the first tap.
  int? get activePlayer => _active;
  bool get isStarted => _active != null;
  bool get isPaused => _paused;
  bool get isRunning => isStarted && !_paused && !isFinished;
  bool get isFinished => _flagged != null;

  /// The player who ran out of time, if any.
  int? get flaggedPlayer => _flagged;

  int moves(int player) => _moves[player];

  Duration remaining(int player) {
    if (player != _active || !isRunning) return _stored[player];
    final left = _stored[player] - (_now() - _turnStartedAt);
    return left.isNegative ? Duration.zero : left;
  }

  /// A tap anywhere on the clock: starts the game, resumes it, or ends the active turn.
  void tap() {
    if (isFinished) return;
    if (!isStarted) {
      _active = 0;
      _turnStartedAt = _now();
      return;
    }
    if (_paused) {
      resume();
      return;
    }
    final player = _active!;
    _commit();
    if (isFinished) return;
    _moves[player]++;
    _active = 1 - player;
    _turnStartedAt = _now();
  }

  /// Call periodically so a player flags as soon as their time hits zero.
  void update() {
    if (isRunning && remaining(_active!) == Duration.zero) _commit();
  }

  void pause() {
    if (!isRunning) return;
    _commit();
    if (!isFinished) _paused = true;
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _turnStartedAt = _now();
  }

  void reset() {
    _stored[0] = _stored[1] = initialTime;
    _moves[0] = _moves[1] = 0;
    _active = null;
    _paused = false;
    _flagged = null;
  }

  void _commit() {
    final player = _active!;
    _stored[player] = remaining(player);
    if (_stored[player] == Duration.zero) _flagged = player;
  }
}
