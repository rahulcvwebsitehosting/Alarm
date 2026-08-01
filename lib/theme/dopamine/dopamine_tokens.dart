import 'package:flutter/material.dart';

import 'package:clock_app/theme/types/color_scheme.dart';

/// Central visual language for the app's vibrant, restrained dark interface.
abstract final class DopamineTokens {
  static const cosmic = Color(0xFF0D0D1A);
  static const surface = Color(0xFF21143B);
  static const surfaceStrong = Color(0xFF2D1B4E);
  static const white = Color(0xFFFFFFFF);

  static const magenta = Color(0xFFFF3AF2);
  static const cyan = Color(0xFF00F5D4);
  static const yellow = Color(0xFFFFE600);
  static const orange = Color(0xFFFF6B35);
  static const purple = Color(0xFF7B2FFF);
  static const danger = Color(0xFFFF5263);

  static const accents = <Color>[magenta, cyan, yellow, orange, purple];

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;
  static const spaceXl = 32.0;

  static const radiusSm = 14.0;
  static const radiusMd = 20.0;
  static const radiusLg = 28.0;
  static const radiusPill = 999.0;

  static const motionFast = Duration(milliseconds: 180);
  static const motionStandard = Duration(milliseconds: 280);

  static Color accentFor(int index) => accents[index % accents.length];

  static Color clashFor(Color accent) {
    if (accent == magenta) return yellow;
    if (accent == cyan) return orange;
    if (accent == yellow) return magenta;
    if (accent == orange) return cyan;
    return yellow;
  }

  static Color inkFor(Color color) =>
      color.computeLuminance() > .48 ? cosmic : white;

  static const colorScheme = ColorScheme.dark(
    primary: magenta,
    onPrimary: cosmic,
    primaryContainer: surfaceStrong,
    onPrimaryContainer: white,
    secondary: cyan,
    onSecondary: cosmic,
    secondaryContainer: surfaceStrong,
    onSecondaryContainer: white,
    tertiary: yellow,
    onTertiary: cosmic,
    tertiaryContainer: surfaceStrong,
    onTertiaryContainer: white,
    error: danger,
    onError: cosmic,
    background: cosmic,
    onBackground: white,
    surface: surface,
    onSurface: white,
    surfaceVariant: surfaceStrong,
    onSurfaceVariant: Color(0xFFE9DFFF),
    outline: magenta,
    outlineVariant: purple,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ColorSchemeData get legacyScheme => ColorSchemeData(
        name: 'Dopamine',
        background: cosmic,
        onBackground: white,
        card: surface,
        onCard: white,
        accent: magenta,
        onAccent: cosmic,
        useAccentAsShadow: true,
        shadow: purple,
        useAccentAsOutline: true,
        outline: magenta,
        error: danger,
        onError: cosmic,
      );

  static List<BoxShadow> stackedShadow(
    Color accent, {
    bool emphasized = false,
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(emphasized ? .30 : .20),
        blurRadius: emphasized ? 24 : 14,
        offset: Offset(0, emphasized ? 10 : 6),
      ),
      if (emphasized)
        BoxShadow(
          color: accent.withOpacity(.10),
          blurRadius: 24,
          spreadRadius: -4,
        ),
    ];
  }
}
