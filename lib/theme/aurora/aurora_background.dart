import 'dart:math' as math;

import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
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
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: DopamineTokens.cosmic),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuroraPainter(
                  progress: _controller.value,
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
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = progress * math.pi * 2;
    _paintDots(canvas, size);
    _paintGlow(
      canvas,
      size,
      Offset(size.width * (.12 + .08 * math.sin(phase)), size.height * .08),
      size.longestSide * .72,
      DopamineTokens.magenta.withOpacity(.10),
    );
    _paintGlow(
      canvas,
      size,
      Offset(size.width * (.88 + .06 * math.cos(phase)), size.height * .38),
      size.longestSide * .62,
      DopamineTokens.cyan.withOpacity(.08),
    );
    _paintGlow(
      canvas,
      size,
      Offset(
          size.width * (.42 + .12 * math.cos(phase * .7)), size.height * .94),
      size.longestSide * .58,
      DopamineTokens.purple.withOpacity(.10),
    );
  }

  void _paintDots(Canvas canvas, Size size) {
    final paint = Paint()..color = DopamineTokens.white.withOpacity(.035);
    for (double y = 22; y < size.height; y += 40) {
      for (double x = 18; x < size.width; x += 40) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
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
      oldDelegate.progress != progress;
}
