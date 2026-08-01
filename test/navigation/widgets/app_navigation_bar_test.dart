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

    expect(navSize.height, lessThanOrEqualTo(90));
    expect(contentSize.height, greaterThan(650));
    expect(find.text('Alarms'), findsOneWidget);
    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Stopwatch'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
