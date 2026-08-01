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
    final clash = DopamineTokens.clashFor(accent);

    return AuroraSurface(
      margin: margin,
      padding: const EdgeInsets.all(20),
      accent: accent,
      emphasized: true,
      rotation: .006,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (backgroundWord != null)
            Positioned(
              right: -14,
              top: -28,
              child: ExcludeSemantics(
                child: Text(
                  backgroundWord!,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: accent.withOpacity(.20),
                    fontSize: 76,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: clash, width: 3),
                    ),
                    child: Icon(
                      icon,
                      color: DopamineTokens.inkFor(accent),
                      size: 27,
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
                            color: clash,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        Text(
                          title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: DopamineTokens.white,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              const Shadow(
                                color: DopamineTokens.purple,
                                offset: Offset(2, 2),
                              ),
                              Shadow(color: accent, offset: const Offset(4, 4)),
                            ],
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
        ],
      ),
    );
  }
}
