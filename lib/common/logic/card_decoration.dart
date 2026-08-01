import 'dart:math' as math;

import 'package:clock_app/theme/types/theme_extension.dart';
import 'package:flutter/material.dart';

BoxDecoration getCardDecoration(BuildContext context,
    {Color? color,
    bool showLightBorder = false,
    bool isSelected = false,
    showShadow = true,
    elevationMultiplier = 1,
    boxShape = BoxShape.rectangle,
    blurStyle = BlurStyle.normal}) {
  ThemeData theme = Theme.of(context);
  ColorScheme colorScheme = theme.colorScheme;
  ThemeStyleExtension? themeStyle = theme.extension<ThemeStyleExtension>();

  final dark = Theme.of(context).brightness == Brightness.dark;
  final resolvedColor = color ?? colorScheme.surface;
  return BoxDecoration(
    border: isSelected
        ? Border.all(
            color: colorScheme.primary,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside)
        : showLightBorder
            ? Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 0.5,
                strokeAlign: BorderSide.strokeAlignInside,
              )
            : (themeStyle?.borderWidth != 0)
                ? Border.all(
                    color: colorScheme.outline,
                    width: themeStyle?.borderWidth ?? 0.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  )
                : Border.all(
                    color:
                        colorScheme.outlineVariant.withOpacity(dark ? .34 : .5),
                    width: .7,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        resolvedColor.withOpacity(dark ? .88 : .92),
        Color.alphaBlend(
          colorScheme.primary.withOpacity(dark ? .055 : .035),
          resolvedColor.withOpacity(dark ? .82 : .88),
        ),
      ],
    ),
    borderRadius: boxShape == BoxShape.rectangle
        ? theme.cardTheme.shape != null
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
            : const BorderRadius.all(Radius.circular(8.0))
        : null,
    shape: boxShape,
    boxShadow: [
      if (showShadow)
        BoxShadow(
          blurStyle: blurStyle,
          color: colorScheme.shadow.withOpacity(
            math.max(themeStyle?.shadowOpacity ?? 0, dark ? .20 : .09),
          ),
          blurRadius: math.max(themeStyle?.shadowBlurRadius ?? 5, 16),
          spreadRadius: themeStyle?.shadowSpreadRadius ?? 0,
          offset: Offset(
              0,
              math.max(
                  (themeStyle?.shadowElevation ?? 1) * elevationMultiplier, 7)),
        ),
    ],
  );
}
