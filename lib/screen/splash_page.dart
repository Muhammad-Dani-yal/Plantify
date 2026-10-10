import 'dart:async';
import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../state/app_state.dart';
import 'home_page.dart';
import 'login_screen.dart';
import 'start_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final state = AppScope.of(context);
      replaceWith(
          context,
          !state.onboardingDone
              ? const StartPage()
              : state.activeSession
                  ? const HomePage()
                  : const LoginScreen());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Botanical.forest,
      body: Stack(children: [
        Positioned(
            top: -120,
            right: -100,
            child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .06),
                        width: 60)))),
        Positioned(
            bottom: -130,
            left: -90,
            child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Botanical.lime.withValues(alpha: .06),
                        width: 70)))),
        Center(
            child: Reveal(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
          const BrandMark(size: 106, color: Botanical.lime),
          const SizedBox(height: 20),
          const Text('plantify.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  letterSpacing: -2)),
          const SizedBox(height: 12),
          const Eyebrow('A little green. A better everyday.',
              color: Botanical.lime),
          const SizedBox(height: 44),
          TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 2100),
              builder: (_, value, __) => SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(3),
                      backgroundColor: Colors.white.withValues(alpha: .12),
                      color: Botanical.lime))),
        ]))),
        const Positioned(
            bottom: 38,
            left: 0,
            right: 0,
            child: Text('DISCOVER  •  NURTURE  •  GROW',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFB3C6B8), fontSize: 10, letterSpacing: 3))),
      ]));
}
