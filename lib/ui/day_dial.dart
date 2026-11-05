// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/session.dart';

/// The part of one session on the 24 hour dial, in hours since midnight.
class DialSpan {
  const DialSpan(this.start, this.end, {this.running = false});

  final double start;
  final double end;
  final bool running;

  @override
  bool operator ==(Object other) =>
      other is DialSpan && other.start == start && other.end == end && other.running == running;

  @override
  int get hashCode => Object.hash(start, end, running);

  @override
  String toString() => 'DialSpan($start – $end${running ? ', running' : ''})';
}

/// The spans of [sessions] on the dial of the day they started.
/// A session that runs past midnight ends at the end of the dial.
List<DialSpan> dialSpans(Iterable<Session> sessions, DateTime now) {
  double hours(DateTime t) => t.hour + t.minute / 60 + t.second / 3600;
  final spans = <DialSpan>[];
  for (final s in sessions) {
    final nextDay = DateTime(s.start.year, s.start.month, s.start.day + 1);
    final end = s.end ?? now;
    final start = hours(s.start);
    final endHour = end.isBefore(nextDay) ? hours(end) : 24.0;
    if (endHour > start) spans.add(DialSpan(start, endHour, running: s.isRunning));
  }
  return spans;
}

/// A day as a 24 hour ring with noon at the top: entries are arcs, breaks gaps.
class DayDial extends StatelessWidget {
  const DayDial({
    super.key,
    required this.sessions,
    required this.now,
    this.hourLabels = true,
    this.strokeRatio = 1 / 18,
    this.child,
  });

  final List<Session> sessions;
  final DateTime now;

  /// Shows 12, 18, 0 and 6 inside the ring.
  final bool hourLabels;

  /// Width of the ring relative to the size of the dial.
  final double strokeRatio;

  /// Sits in the middle of the ring.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _DialPainter(
        spans: dialSpans(sessions, now),
        strokeRatio: strokeRatio,
        track: scheme.surfaceContainerHighest,
        done: scheme.primary,
        running: scheme.tertiary,
        labels: hourLabels ? scheme.onSurfaceVariant : null,
      ),
      child: Center(child: child),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.spans,
    required this.strokeRatio,
    required this.track,
    required this.done,
    required this.running,
    required this.labels,
  });

  final List<DialSpan> spans;
  final double strokeRatio;
  final Color track;
  final Color done;
  final Color running;
  final Color? labels;

  /// Keeps a just started entry visible: about 15 minutes.
  static const _minSweep = pi / 48;

  static double _angle(double hour) => (hour - 12) / 24 * 2 * pi - pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = size.center(Offset.zero);
    final stroke = side * strokeRatio;
    final radius = (side - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, paint..color = track);
    for (final s in spans) {
      final sweep = max(_angle(s.end) - _angle(s.start), _minSweep);
      canvas.drawArc(
        rect,
        _angle(s.start),
        sweep,
        false,
        paint..color = s.running ? running : done,
      );
    }

    final labelColor = labels;
    if (labelColor == null) return;
    final labelRadius = radius - stroke;
    for (final hour in const [12, 18, 0, 6]) {
      final text = TextPainter(
        text: TextSpan(
          text: '$hour',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final a = _angle(hour.toDouble());
      final at = center + Offset(cos(a), sin(a)) * labelRadius;
      text.paint(canvas, at - text.size.center(Offset.zero));
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.strokeRatio != strokeRatio ||
      old.track != track ||
      old.done != done ||
      old.running != running ||
      old.labels != labels ||
      old.spans.length != spans.length ||
      !Iterable.generate(spans.length).every((i) => old.spans[i] == spans[i]);
}

/// The day dial with the big start/stop button in its middle.
class StartStopDial extends StatelessWidget {
  const StartStopDial({
    super.key,
    required this.sessions,
    required this.now,
    required this.running,
    required this.onPressed,
  });

  final List<Session> sessions;
  final DateTime now;
  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = running ? theme.colorScheme.tertiary : theme.colorScheme.primary;
    final foreground = running ? theme.colorScheme.onTertiary : theme.colorScheme.onPrimary;
    return Center(
      child: ConstrainedBox(
        // Smaller on short screens, so the entries below stay in view.
        constraints: BoxConstraints(maxWidth: min(288, MediaQuery.sizeOf(context).height * 0.4)),
        child: AspectRatio(
          aspectRatio: 1,
          child: DayDial(
            sessions: sessions,
            now: now,
            child: FractionallySizedBox(
              widthFactor: 0.66,
              heightFactor: 0.66,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  minimumSize: Size.zero,
                  backgroundColor: background,
                  foregroundColor: foreground,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 56),
                      Text(
                        running ? 'Stop logging' : 'Start logging',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
