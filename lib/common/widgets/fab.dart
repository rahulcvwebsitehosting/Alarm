import 'package:clock_app/icons/flux_icons.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/types/setting.dart';
import 'package:clock_app/theme/types/theme_extension.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';

enum FabPosition { bottomLeft, bottomRight }

class FAB extends StatefulWidget {
  const FAB({
    super.key,
    this.onPressed,
    this.icon = FluxIcons.add,
    this.index = 0,
    this.bottomPadding = 0,
    this.size = 1,
    this.position = FabPosition.bottomRight,
    this.semanticLabel = 'Add',
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final int index;
  final double bottomPadding;
  final double size;
  final FabPosition position;
  final String semanticLabel;

  @override
  State<FAB> createState() => _FABState();
}

class _FABState extends State<FAB> {
  late Setting _leftHandedMode;

  void update(value) {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _leftHandedMode =
        appSettings.getGroup("Accessibility").getSetting("Left Handed Mode");
    _leftHandedMode.addListener(update);
  }

  @override
  void dispose() {
    _leftHandedMode.removeListener(update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ThemeSettingExtension themeSettings =
        theme.extension<ThemeSettingExtension>()!;
    final accent = DopamineTokens.accentFor(widget.index);
    final clash = DopamineTokens.clashFor(accent);

    final position = _leftHandedMode.value
        ? widget.position == FabPosition.bottomRight
            ? FabPosition.bottomLeft
            : FabPosition.bottomRight
        : widget.position;

    double bottomPadding = themeSettings.useMaterialStyle
        ? widget.bottomPadding + 20
        : widget.bottomPadding;

    return Positioned(
      bottom: bottomPadding,
      right: position == FabPosition.bottomRight
          ? 16 + (widget.index * 24 * widget.size) + widget.index * 36
          : null,
      left: position == FabPosition.bottomLeft
          ? 16 + (widget.index * 24 * widget.size) + widget.index * 36
          : null,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DopamineTokens.radiusMd),
            color: accent,
            border: Border.all(color: clash, width: 3),
            boxShadow: DopamineTokens.stackedShadow(accent, emphasized: true),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(DopamineTokens.radiusMd),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  widget.icon,
                  color: DopamineTokens.inkFor(accent),
                  size: 24 * widget.size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
