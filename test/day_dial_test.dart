// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelogbook/models/session.dart';
import 'package:timelogbook/ui/app_theme.dart';
import 'package:timelogbook/ui/day_dial.dart';
import 'package:timelogbook/ui/day_view.dart';

void main() {
  final now = DateTime(2026, 11, 5, 15, 12);
  final done = Session(id: 1, start: DateTime(2026, 11, 5, 7, 30), end: DateTime(2026, 11, 5, 12));
  final running = Session(id: 2, start: DateTime(2026, 11, 5, 12, 30));

  group('dialSpans', () {
    test('finished and running entries become spans in hours', () {
      expect(dialSpans([done, running], now), const [
        DialSpan(7.5, 12),
        DialSpan(12.5, 15.2, running: true),
      ]);
    });

    test('an entry past midnight ends at the end of the dial', () {
      final night = Session(start: DateTime(2026, 11, 4, 22), end: DateTime(2026, 11, 5, 1));
      expect(dialSpans([night], now), const [DialSpan(22, 24)]);
    });

    test('an entry still running from yesterday fills the rest of the dial', () {
      final night = Session(start: DateTime(2026, 11, 4, 22));
      expect(dialSpans([night], now), const [DialSpan(22, 24, running: true)]);
    });

    test('no sessions, no spans', () => expect(dialSpans(const [], now), isEmpty));
  });

  Widget app(Widget child) => MaterialApp(
    theme: lightTheme,
    home: Scaffold(body: child),
  );

  group('StartStopDial', () {
    testWidgets('offers start when stopped', (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        app(StartStopDial(sessions: [done], now: now, running: false, onPressed: () => pressed++)),
      );
      expect(find.text('Start logging'), findsOneWidget);
      await tester.tap(find.text('Start logging'));
      expect(pressed, 1);
    });

    testWidgets('offers stop when running', (tester) async {
      await tester.pumpWidget(
        app(StartStopDial(sessions: [done, running], now: now, running: true, onPressed: () {})),
      );
      expect(find.text('Stop logging'), findsOneWidget);
    });

    testWidgets('fits a narrow screen', (tester) async {
      await tester.pumpWidget(
        app(
          SizedBox(
            width: 200,
            child: StartStopDial(sessions: const [], now: now, running: false, onPressed: () {}),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SessionList', () {
    testWidgets('shows a hint for an empty day', (tester) async {
      await tester.pumpWidget(app(SessionList(sessions: const [], now: now)));
      expect(find.text('No entries yet.'), findsOneWidget);
    });

    testWidgets('shows finished and running entries', (tester) async {
      Session? tapped;
      await tester.pumpWidget(
        app(SessionList(sessions: [done, running], now: now, onTap: (s) => tapped = s)),
      );
      expect(find.text('07:30 – 12:00'), findsOneWidget);
      expect(find.text('12:30 – running'), findsOneWidget);
      expect(find.text('2:42'), findsOneWidget);
      await tester.tap(find.text('12:30 – running'));
      expect(tapped, running);
    });

    testWidgets('marks an entry past midnight', (tester) async {
      final night = Session(start: DateTime(2026, 11, 4, 22), end: DateTime(2026, 11, 5, 1));
      await tester.pumpWidget(app(SessionList(sessions: [night], now: now)));
      expect(find.text('22:00 – 01:00 (+1 day)'), findsOneWidget);
    });
  });
}
