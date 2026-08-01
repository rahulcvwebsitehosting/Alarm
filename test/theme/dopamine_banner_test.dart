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

    expect(find.text('OWN THE MOMENT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('banner remains usable in phone landscape', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpBanner(tester, const Size(667, 375));

    expect(find.byType(DopamineBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
