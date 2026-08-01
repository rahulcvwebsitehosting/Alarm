import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A resolution-independent ambient background. The painter uses gradients,
/// so the artwork remains sharp on phones, tablets, foldables, and 4K screens.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.18;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: scheme.background),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuroraPainter(
                  progress: _controller.value,
                  scheme: scheme,
                  brightness: Theme.of(context).brightness,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({
    required this.progress,
    required this.scheme,
    required this.brightness,
  });

  final double progress;
  final ColorScheme scheme;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = brightness == Brightness.dark;
    final phase = progress * math.pi * 2;
    _paintGlow(
      canvas,
      size,
      Offset(size.width * (.12 + .08 * math.sin(phase)), size.height * .08),
      size.longestSide * .72,
      scheme.primary.withOpacity(dark ? .25 : .16),
    );
    _paintGlow(
      canvas,
      size,
      Offset(size.width * (.88 + .06 * math.cos(phase)), size.height * .38),
      size.longestSide * .62,
      scheme.tertiary.withOpacity(dark ? .18 : .12),
    );
    _paintGlow(
      canvas,
      size,
      Offset(
          size.width * (.42 + .12 * math.cos(phase * .7)), size.height * .94),
      size.longestSide * .58,
      scheme.secondary.withOpacity(dark ? .14 : .10),
    );
  }

  void _paintGlow(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.scheme != scheme ||
      oldDelegate.brightness != brightness;
}
