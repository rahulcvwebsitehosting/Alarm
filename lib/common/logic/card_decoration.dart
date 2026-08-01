import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';

BoxDecoration getCardDecoration(BuildContext context,
    {Color? color,
    bool showLightBorder = false,
    bool isSelected = false,
    showShadow = true,
    elevationMultiplier = 1,
    boxShape = BoxShape.rectangle,
    blurStyle = BlurStyle.normal,
    Color? accent}) {
  final theme = Theme.of(context);
  final resolvedColor = color ?? DopamineTokens.surface;
  final resolvedAccent = accent ?? DopamineTokens.magenta;
  return BoxDecoration(
    border: isSelected
        ? Border.all(
            color: DopamineTokens.cyan,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside)
        : Border.all(
            color: showLightBorder
                ? DopamineTokens.white.withOpacity(.18)
                : resolvedAccent.withOpacity(.40),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          resolvedAccent.withOpacity(.05),
          resolvedColor.withOpacity(.96),
        ),
        Color.alphaBlend(
          DopamineTokens.purple.withOpacity(.05),
          DopamineTokens.surfaceStrong.withOpacity(.94),
        ),
      ],
    ),
    borderRadius: boxShape == BoxShape.rectangle
        ? theme.cardTheme.shape != null
            ? (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius
            : const BorderRadius.all(Radius.circular(8.0))
        : null,
    shape: boxShape,
    boxShadow: showShadow
        ? DopamineTokens.stackedShadow(resolvedAccent)
        : const <BoxShadow>[],
  );
}
