import 'package:clock_app/navigation/widgets/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile navigation stays compact and leaves room for content',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: const SizedBox.expand(key: Key('page-content')),
          bottomNavigationBar: AppNavigationBar(
            selectedTabIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navSize = tester.getSize(find.byType(AppNavigationBar));
    final contentSize = tester.getSize(find.byKey(const Key('page-content')));
    final navigationButtons = find.descendant(
      of: find.byType(AppNavigationBar),
      matching: find.byType(InkWell),
    );

    expect(navSize.height, inInclusiveRange(78, 90));
    expect(contentSize.height, greaterThan(700));
    expect(navigationButtons, findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('all navigation labels remain visible with large system text',
      (tester) async {
    const size = Size(320, 640);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            bottomNavigationBar: AppNavigationBar(
              selectedTabIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alarm'), findsOneWidget);
    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Stopwatch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
