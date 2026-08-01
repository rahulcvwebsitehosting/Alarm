import 'package:clock_app/theme/dopamine/dopamine_banner.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          colorScheme: DopamineTokens.colorScheme,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: DopamineBanner(
                eyebrow: 'Motion ready',
                title: 'Own the moment',
                subtitle: 'A readable, responsive maximalist surface.',
                backgroundWord: 'GO',
                icon: Icons.bolt_rounded,
                accent: DopamineTokens.cyan,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('banner fits a 375dp phone with large text', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpBanner(tester, const Size(375, 667), textScale: 1.8);

    expect(find.text('Own the moment'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full-width action label stays visible on a narrow phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const size = Size(320, 640);
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          colorScheme: DopamineTokens.colorScheme,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: DopamineBanner(
                eyebrow: 'One quick setup',
                title: 'Never miss the moment',
                subtitle: 'Keep alarms reliable in the background.',
                icon: Icons.notifications_active_rounded,
                accent: DopamineTokens.magenta,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text(
                      'Open settings',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Open settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner remains usable in phone landscape', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpBanner(tester, const Size(667, 375));

    expect(find.byType(DopamineBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
