import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:clock_app/theme/bottom_sheet.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:clock_app/theme/popup_menu.dart';
import 'package:clock_app/theme/slider.dart';
import 'package:clock_app/theme/switch.dart';
import 'package:clock_app/theme/theme.dart';
import 'package:clock_app/theme/types/color_scheme.dart';
import 'package:clock_app/theme/input.dart';
import 'package:clock_app/theme/radio.dart';
import 'package:clock_app/theme/snackbar.dart';
import 'package:clock_app/theme/types/style_theme.dart';
import 'package:clock_app/theme/types/theme_extension.dart';
import 'package:flutter/material.dart';

ColorSchemeData getColorSchemeData(ColorScheme colorScheme) {
  return ColorSchemeData(
    background: colorScheme.background,
    onBackground: colorScheme.onBackground,
    card: colorScheme.surface,
    onCard: colorScheme.onSurface,
    accent: colorScheme.primary,
    onAccent: colorScheme.onPrimary,
    error: colorScheme.error,
    onError: colorScheme.onError,
  );
}

// ThemeData getThemeFromColorScheme(ThemeData theme, ColorScheme colorScheme) {
//
//   ColorSchemeData colorSchemeData = getColorSchemeData(colorScheme);
//
//   return getThemeFromColorSchemeData(theme, colorSchemeData);
//
//
// }
//
ThemeData getTheme(
    {ColorScheme? colorScheme,
    ColorSchemeData? colorSchemeData,
    StyleTheme? styleTheme}) {
  SettingGroup appearanceSettings = appSettings.getGroup("Appearance");
  SettingGroup colorSettings = appearanceSettings.getGroup("Colors");
  SettingGroup styleSettings = appearanceSettings.getGroup("Style");

  styleTheme ??= styleSettings.getSetting("Style Theme").value;

  colorSchemeData ??= colorScheme != null
      ? getColorSchemeData(colorScheme)
      : colorSettings.getSetting("Color Scheme").value;

  bool useMaterialYou = colorSettings.getSetting("Use Material You").value;
  bool useMaterialStyle = styleSettings.getSetting("Use Material Style").value;

  if (styleTheme == null || colorSchemeData == null) {
    return defaultTheme;
  }
  final resolvedScheme = DopamineTokens.colorScheme;
  final resolvedData = DopamineTokens.legacyScheme;
  final dopamineShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(DopamineTokens.radiusLg),
    side: BorderSide(color: DopamineTokens.magenta.withOpacity(.45)),
  );

  return defaultTheme.copyWith(
    colorScheme: resolvedScheme,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: DopamineTokens.cosmic,
    cardColor: DopamineTokens.surface,
    radioTheme: getRadioTheme(resolvedData),
    dialogBackgroundColor: DopamineTokens.surfaceStrong,
    bottomSheetTheme: getBottomSheetTheme(resolvedData, styleTheme).copyWith(
      backgroundColor: DopamineTokens.surfaceStrong,
      modalBackgroundColor: DopamineTokens.surfaceStrong,
      shape: dopamineShape,
    ),
    textTheme: defaultTheme.textTheme
        .apply(
          bodyColor: DopamineTokens.white,
          displayColor: DopamineTokens.white,
        )
        .copyWith(
          headlineSmall: defaultTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.35,
          ),
          titleLarge: defaultTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
    splashColor: DopamineTokens.cyan.withOpacity(.20),
    highlightColor: DopamineTokens.yellow.withOpacity(.10),
    dividerColor: DopamineTokens.cyan.withOpacity(.34),
    snackBarTheme: getSnackBarTheme(resolvedData, styleTheme),
    inputDecorationTheme: getInputTheme(resolvedData, styleTheme).copyWith(
      filled: true,
      fillColor: DopamineTokens.surfaceStrong.withOpacity(.86),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DopamineTokens.radiusMd),
        borderSide: BorderSide(
          color: DopamineTokens.magenta.withOpacity(.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DopamineTokens.radiusMd),
        borderSide: const BorderSide(color: DopamineTokens.cyan, width: 1.5),
      ),
    ),
    popupMenuTheme: getPopupMenuTheme(resolvedData, styleTheme).copyWith(
      color: DopamineTokens.surfaceStrong,
      surfaceTintColor: Colors.transparent,
      shape: dopamineShape,
    ),
    switchTheme: getSwitchTheme(resolvedData),
    sliderTheme: getSliderTheme(resolvedData),
    cardTheme: defaultTheme.cardTheme.copyWith(shape: dopamineShape),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DopamineTokens.radiusPill),
        ),
        backgroundColor: DopamineTokens.magenta,
        foregroundColor: DopamineTokens.cosmic,
        side: BorderSide(color: DopamineTokens.white.withOpacity(.16)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: DopamineTokens.cyan.withOpacity(.72)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DopamineTokens.radiusPill),
        ),
        foregroundColor: DopamineTokens.white,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .1,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: DopamineTokens.cyan,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: DopamineTokens.cyan,
      linearTrackColor: DopamineTokens.surfaceStrong,
      circularTrackColor: DopamineTokens.surfaceStrong,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DopamineTokens.cosmic,
      foregroundColor: DopamineTokens.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: DopamineTokens.surface,
      indicatorColor: DopamineTokens.yellow,
      selectedIconTheme: IconThemeData(color: DopamineTokens.cosmic),
      unselectedIconTheme: IconThemeData(color: DopamineTokens.cyan),
      selectedLabelTextStyle: TextStyle(
        color: DopamineTokens.white,
        fontWeight: FontWeight.w800,
      ),
    ),
    timePickerTheme: defaultTheme.timePickerTheme.copyWith(
      shape: dopamineShape,
      dayPeriodShape: dopamineShape,
      hourMinuteShape: dopamineShape,
    ),
    toggleButtonsTheme: defaultTheme.toggleButtonsTheme.copyWith(
      borderRadius: BorderRadius.circular(DopamineTokens.radiusPill),
      borderColor: DopamineTokens.cyan,
      selectedBorderColor: DopamineTokens.yellow,
      selectedColor: DopamineTokens.cosmic,
      fillColor: DopamineTokens.yellow,
    ),
    extensions: [
      defaultTheme.extension<ThemeStyleExtension>()?.copyWith(
                borderRadius: DopamineTokens.radiusLg,
                shadowElevation: 3,
                shadowBlurRadius: 14,
                shadowOpacity: .20,
                shadowSpreadRadius: 0,
                borderWidth: 1,
              ) ??
          const ThemeStyleExtension(),
      defaultTheme.extension<ThemeSettingExtension>()?.copyWith(
                useMaterialYou: useMaterialYou,
                useMaterialStyle: useMaterialStyle,
              ) ??
          const ThemeSettingExtension(),
    ],
  );
}
