import 'dart:ui';

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
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surfaceOpacity = dark ? .66 : .72;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: emphasized
              ? [
                  scheme.primary.withOpacity(dark ? .34 : .22),
                  scheme.tertiary.withOpacity(dark ? .20 : .12),
                ]
              : [
                  scheme.surface.withOpacity(surfaceOpacity),
                  scheme.surfaceVariant.withOpacity(surfaceOpacity * .72),
                ],
        ),
        border: Border.all(
          color: (emphasized ? scheme.primary : scheme.outlineVariant)
              .withOpacity(dark ? .34 : .42),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(dark ? .24 : .10),
            blurRadius: emphasized ? 30 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: onTap == null
              ? content
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: onTap,
                    child: content,
                  ),
                ),
        ),
      ),
    );
  }
}
