import 'dart:ui';

import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';

class AuroraSurface extends StatelessWidget {
  const AuroraSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    this.emphasized = false,
    this.accent,
    this.rotation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool emphasized;
  final Color? accent;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final resolvedAccent = accent ?? DopamineTokens.magenta;
    final paddedChild = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );
    final content = onTap == null
        ? paddedChild
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: paddedChild,
            ),
          );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Transform.rotate(
        // Keep the public property for compatibility, but strongly restrain
        // decorative tilt so content remains visually stable.
        angle: rotation / 5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: DopamineTokens.stackedShadow(
              resolvedAccent,
              emphasized: emphasized,
            ),
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.alphaBlend(
                        resolvedAccent.withOpacity(emphasized ? .10 : .05),
                        DopamineTokens.surfaceStrong.withOpacity(.94),
                      ),
                      DopamineTokens.surface.withOpacity(.92),
                    ],
                  ),
                  border: Border.all(
                    color: resolvedAccent.withOpacity(emphasized ? .72 : .42),
                    width: emphasized ? 1.5 : 1,
                  ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
