// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

const _fontFamily = 'Manrope';

/// Digits of equal width, so running times don't jitter.
const tabularFigures = [FontFeature.tabularFigures()];

/// Roles beyond the plain Material ones:
/// `tertiary` is the "logging" colour (running entry, stop button),
/// `surfaceContainer` the colour of cards,
/// `surfaceContainerHighest` the empty part of the day dial.
final lightTheme = _theme(
  ColorScheme.fromSeed(seedColor: const Color(0xFF1F5FD6)).copyWith(
    primary: const Color(0xFF1F5FD6),
    onPrimary: Colors.white,
    tertiary: const Color(0xFFC2410C),
    onTertiary: Colors.white,
    error: const Color(0xFFB42318),
    surface: const Color(0xFFF2F5F8),
    onSurface: const Color(0xFF101C2B),
    onSurfaceVariant: const Color(0xFF51606F),
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHighest: const Color(0xFFDDE4EC),
    outlineVariant: const Color(0xFFD7DEE6),
  ),
);

final darkTheme = _theme(
  ColorScheme.fromSeed(seedColor: const Color(0xFF1F5FD6), brightness: Brightness.dark).copyWith(
    primary: const Color(0xFF7FA8F5),
    onPrimary: const Color(0xFF0B1A33),
    tertiary: const Color(0xFFFF8A4C),
    onTertiary: const Color(0xFF2A1003),
    surface: const Color(0xFF0E1620),
    onSurface: const Color(0xFFEEF3F8),
    onSurfaceVariant: const Color(0xFFA4B2C1),
    surfaceContainerLow: const Color(0xFF17212D),
    surfaceContainer: const Color(0xFF17212D),
    surfaceContainerHighest: const Color(0xFF26323F),
    outlineVariant: const Color(0xFF2A3644),
  ),
);

ThemeData _theme(ColorScheme scheme) {
  final title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: scheme.onSurface,
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: _fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
      titleTextStyle: title,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: title.copyWith(fontSize: 22),
    ),
  );
}
