import 'package:clock_app/navigation/data/tabs.dart';
import 'package:clock_app/navigation/types/tab.dart';
import 'package:clock_app/theme/aurora/aurora_surface.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: SizedBox(
        height: 66,
        child: AuroraSurface(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(4),
          accent: DopamineTokens.cyan,
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
                        height: 56,
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: widget.selectedTabIndex == index
                              ? DopamineTokens.accentFor(index).withOpacity(.14)
                              : Colors.transparent,
                          border: widget.selectedTabIndex == index
                              ? Border.all(
                                  color: DopamineTokens.accentFor(index)
                                      .withOpacity(.70),
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
                              color: DopamineTokens.accentFor(index),
                            ),
                            const SizedBox(height: 3),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tabs[index].title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontWeight:
                                            widget.selectedTabIndex == index
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color: DopamineTokens.white,
                                      ),
                                ),
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
