import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chess_clock/chess_clock.dart';
import 'package:chess_clock/main.dart';

void main() {
  group('ChessClock', () {
    late Duration now;
    late ChessClock clock;

    setUp(() {
      now = Duration.zero;
      clock = ChessClock(
        initialTime: const Duration(minutes: 5),
        now: () => now,
      );
    });

    test('first tap starts player 1, next taps alternate', () {
      expect(clock.isStarted, isFalse);
      clock.tap();
      expect(clock.activePlayer, 0);

      now += const Duration(seconds: 10);
      expect(clock.remaining(0), const Duration(minutes: 4, seconds: 50));
      clock.tap();
      expect(clock.activePlayer, 1);
      expect(clock.moves(0), 1);

      now += const Duration(seconds: 3);
      expect(clock.remaining(0), const Duration(minutes: 4, seconds: 50));
      expect(clock.remaining(1), const Duration(minutes: 4, seconds: 57));
      clock.tap();
      expect(clock.activePlayer, 0);
    });

    test('pause freezes time and tap resumes without switching', () {
      clock.tap();
      now += const Duration(seconds: 5);
      clock.pause();
      now += const Duration(minutes: 1);
      expect(clock.remaining(0), const Duration(minutes: 4, seconds: 55));
      clock.tap();
      expect(clock.isPaused, isFalse);
      expect(clock.activePlayer, 0);
    });

    test('player flags at zero and further taps are ignored', () {
      clock.tap();
      now += const Duration(minutes: 6);
      clock.update();
      expect(clock.isFinished, isTrue);
      expect(clock.flaggedPlayer, 0);
      expect(clock.remaining(0), Duration.zero);
      clock.tap();
      expect(clock.activePlayer, 0);
    });

    test('reset restores initial state', () {
      clock.tap();
      now += const Duration(seconds: 30);
      clock.tap();
      clock.reset();
      expect(clock.isStarted, isFalse);
      expect(clock.remaining(0), const Duration(minutes: 5));
      expect(clock.moves(0), 0);
    });
  });

  testWidgets('select 10 min, start, and tap to run the clock', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('10 min'));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('10:00'), findsNWidgets(2));
    expect(find.text('Tap anywhere to start'), findsOneWidget);

    // Tap on player 2's half: the whole screen counts, so player 1 starts.
    await tester.tapAt(const Offset(200, 50));
    await tester.pump();
    expect(find.text('Tap anywhere to start'), findsNothing);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Leave the screen so the periodic timer is disposed.
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });
}
