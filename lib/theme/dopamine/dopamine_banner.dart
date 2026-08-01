import 'package:clock_app/theme/aurora/aurora_surface.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';

class DopamineBanner extends StatelessWidget {
  const DopamineBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.accent,
    this.subtitle,
    this.backgroundWord,
    this.child,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(18, 10, 24, 18),
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? backgroundWord;
  final IconData icon;
  final Color accent;
  final Widget? child;
  final Widget? trailing;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuroraSurface(
      margin: margin,
      padding: const EdgeInsets.all(20),
      accent: accent,
      emphasized: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DopamineTokens.white.withOpacity(.18),
                  ),
                ),
                child: Icon(
                  icon,
                  color: DopamineTokens.inkFor(accent),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    Text(
                      title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: DopamineTokens.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DopamineTokens.white.withOpacity(.84),
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 18),
            child!,
          ],
        ],
      ),
    );
  }
}
