import 'package:clock_app/navigation/data/tabs.dart';
import 'package:clock_app/navigation/types/tab.dart';
import 'package:clock_app/theme/aurora/aurora_surface.dart';
import 'package:flutter/material.dart' hide Tab;

class AppNavigationBar extends StatefulWidget {
  final int selectedTabIndex;
  final void Function(int) onTabSelected;

  const AppNavigationBar(
      {super.key, required this.selectedTabIndex, required this.onTabSelected});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = getTabs(context);
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: SizedBox(
        height: 66,
        child: AuroraSurface(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              for (var index = 0; index < tabs.length; index++)
                Expanded(
                  child: Semantics(
                    selected: widget.selectedTabIndex == index,
                    button: true,
                    label: tabs[index].title,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => widget.onTabSelected(index),
                      child: AnimatedContainer(
                        height: 54,
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: widget.selectedTabIndex == index
                              ? LinearGradient(
                                  colors: [
                                    scheme.primary,
                                    scheme.tertiary,
                                  ],
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tabs[index].icon,
                              size: 22,
                              color: widget.selectedTabIndex == index
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              tabs[index].title,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: widget.selectedTabIndex == index
                                        ? scheme.onPrimary
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
