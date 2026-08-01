import 'package:clock_app/common/logic/card_decoration.dart';
import 'package:clock_app/navigation/screens/nav_scaffold.dart';
import 'package:clock_app/settings/data/settings_schema.dart';
import 'package:clock_app/settings/screens/settings_group_screen.dart';
import 'package:clock_app/theme/dopamine/dopamine_banner.dart';
import 'package:clock_app/theme/dopamine/dopamine_tokens.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  OnBoardingScreenState createState() => OnBoardingScreenState();
}

class OnBoardingScreenState extends State<OnBoardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  void _onIntroEnd(context) {
    GetStorage().write('onboarded', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const NavScaffold()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Colors.transparent,
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,
      pages: [
        PageViewModel(
          titleWidget: const SizedBox.shrink(),
          bodyWidget: DopamineBanner(
            eyebrow: 'One quick setup',
            title: 'Never miss the moment',
            subtitle:
                'Some phones restrict alarms in the background. Open reliability settings once so alarms and timers can always fire on time.',
            backgroundWord: 'LOUD',
            icon: Icons.notifications_active_rounded,
            accent: DopamineTokens.magenta,
            margin: const EdgeInsets.fromLTRB(8, 24, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingGroupScreen(
                                settingGroup:
                                    appSettings.getGroup("Reliability"),
                                isAppSettings: false,
                              )));
                },
                icon: const Icon(Icons.tune_rounded),
                label: const Text(
                  'Open settings',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back),
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w700)),
      next: const Icon(Icons.arrow_forward),
      done:
          const Text('LET’S GO', style: TextStyle(fontWeight: FontWeight.w900)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: DopamineTokens.purple,
        activeColor: DopamineTokens.yellow,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      dotsContainerDecorator: getCardDecoration(
        context,
        accent: DopamineTokens.cyan,
      ),
    );
  }
}
