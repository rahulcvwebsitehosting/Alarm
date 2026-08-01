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
  final resolvedColor = color ?? DopamineTokens.surface;
  final resolvedAccent = accent ?? DopamineTokens.magenta;
  final clash = DopamineTokens.clashFor(resolvedAccent);
  return BoxDecoration(
    border: isSelected
        ? Border.all(
            color: DopamineTokens.cyan,
            width: 4,
            strokeAlign: BorderSide.strokeAlignOutside)
        : Border.all(
            color: showLightBorder ? clash : resolvedAccent,
            width: showLightBorder ? 2 : 3,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          resolvedAccent.withOpacity(.12),
          resolvedColor.withOpacity(.96),
        ),
        Color.alphaBlend(
          DopamineTokens.purple.withOpacity(.14),
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
