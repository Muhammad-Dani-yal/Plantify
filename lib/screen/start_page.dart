import 'dart:async';
import 'package:flutter/material.dart';
import '../components/app_theme.dart';
import '../components/botanical_widgets.dart';
import '../data/plants.dart';
import '../state/app_state.dart';
import 'login_screen.dart';
import 'home_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});
  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _playing = true;
  static const _scenes = [
    (
      'Your next green\nobsession starts here.',
      'Discover a whole world of plants, from easy first companions to your next statement leaf.',
      'assets/botanical/greenhouse-hero.png',
      'A world of green',
      'Discover'
    ),
    (
      'Less guessing.\nMore growing.',
      'Get to know the light, soil, and little routines that help each plant feel at home.',
      'assets/botanical/monstera.png',
      'Monstera deliciosa',
      'Learn'
    ),
    (
      'A garden that\ngrows with you.',
      'Build your collection, keep care notes, and take your garden with you across your devices.',
      'assets/botanical/lavender.png',
      'Lavandula angustifolia',
      'Grow'
    ),
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_playing || MediaQuery.disableAnimationsOf(context)) return;
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _scenes.length);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _select(int index) {
    setState(() => _index = index);
    _startTimer();
  }

  void _finish() {
    final state = AppScope.of(context);
    state.completeOnboarding();
    replaceWith(
        context, state.activeSession ? const HomePage() : const LoginScreen());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scenes[_index];
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: reduced ? 0 : 650);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        body: DecoratedBox(
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [
                      const Color(0xFF14271F),
                      const Color(0xFF253D32),
                      const Color(0xFF14271F)
                    ]
                  : [
                      const Color(0xFFE3ECD7),
                      const Color(0xFFF3E8D8),
                      const Color(0xFFDCE9DE)
                    ])),
      child: SafeArea(
          child: PageBody(maxWidth: 1160, children: [
        Row(children: [
          const Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Wordmark()))),
          TextButton(onPressed: _finish, child: const Text('Get started')),
        ]),
        const SizedBox(height: 28),
        LayoutBuilder(builder: (_, constraints) {
          final wide = constraints.maxWidth >= 780;
          final art = ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: SizedBox(
                  height: wide ? 560 : 360,
                  child: Stack(fit: StackFit.expand, children: [
                    AnimatedSwitcher(
                        duration: duration,
                        child: Image.asset(scene.$3,
                            key: ValueKey(_index),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover)),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Color(0x15183F32),
                          Colors.transparent,
                          Color(0xDD183F32)
                        ],
                                stops: [
                          0,
                          .45,
                          1
                        ]))),
                    Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                                color: Botanical.lime,
                                borderRadius: BorderRadius.circular(30)),
                            child: const Text('A LITTLE GREEN GOES A LONG WAY',
                                style: TextStyle(
                                    color: Botanical.forest,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1)))),
                    Positioned(
                        left: 24,
                        right: 24,
                        bottom: 24,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(scene.$4,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'DMSerifDisplay',
                                      fontSize: 32)),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: Wrap(
                                        spacing: 7,
                                        children: List.generate(
                                            3,
                                            (i) => Semantics(
                                                selected: _index == i,
                                                child: InkWell(
                                                    onTap: () => _select(i),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    child: AnimatedContainer(
                                                        duration: duration,
                                                        width: _index == i
                                                            ? 42
                                                            : 16,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                            color: _index == i
                                                                ? Botanical.lime
                                                                : Colors
                                                                    .white54,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)))))))),
                                IconButton(
                                    tooltip: _playing
                                        ? 'Pause slideshow'
                                        : 'Play slideshow',
                                    style: IconButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: .12)),
                                    onPressed: () {
                                      setState(() => _playing = !_playing);
                                      _startTimer();
                                    },
                                    icon: Icon(_playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded)),
                              ]),
                            ])),
                  ])));
          final copy =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow('${plants.length} care profiles. A world to discover.'),
            const SizedBox(height: 18),
            AnimatedSwitcher(
                duration: duration,
                layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topLeft,
                    children: [...previous, if (current != null) current]),
                child: Text(scene.$1,
                    key: ValueKey('title-$_index'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontSize: wide ? 50 : 36))),
            const SizedBox(height: 20),
            Text(scene.$2, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 22),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < 3; i++)
                ActionChip(
                    avatar: Icon(
                        [
                          Icons.explore_outlined,
                          Icons.menu_book_outlined,
                          Icons.spa_outlined
                        ][i],
                        size: 17),
                    label: Text(_scenes[i].$5),
                    onPressed: () => _select(i)),
            ]),
            const SizedBox(height: 28),
            PlantButton(
                label: 'Start your green journey',
                accent: true,
                onPressed: _finish),
            const SizedBox(height: 14),
            const Text('Your plants. Your pace. Your own little jungle.',
                style: TextStyle(fontSize: 12)),
          ]);
          return wide
              ? Row(children: [
                  Expanded(flex: 6, child: art),
                  const SizedBox(width: 48),
                  Expanded(flex: 5, child: copy)
                ])
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [art, const SizedBox(height: 28), copy]);
        }),
        const SizedBox(height: 34),
        LayoutBuilder(builder: (_, c) {
          final cards = [
            const _WelcomeFeature(
                Icons.travel_explore,
                'Find your kind of green',
                'Explore care profiles and a worldwide botanical catalogue.',
                Botanical.sage),
            const _WelcomeFeature(
                Icons.favorite_border,
                'Keep your favourites close',
                'Save the leaves you love and build your wish list.',
                Botanical.peach),
            const _WelcomeFeature(
                Icons.water_drop_outlined,
                'Make care a little easier',
                'Track watering, add notes, and watch your garden grow.',
                Botanical.lavender),
          ];
          return c.maxWidth >= 760
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    Expanded(child: cards[i])
                  ],
                ])
              : Column(children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12)
                  ]
                ]);
        }),
        const SizedBox(height: 12),
      ])),
    ));
  }
}

class _WelcomeFeature extends StatelessWidget {
  const _WelcomeFeature(this.icon, this.title, this.copy, this.color);
  final IconData icon;
  final String title, copy;
  final Color color;
  @override
  Widget build(BuildContext context) => SurfaceBox(
      color: Theme.of(context).brightness == Brightness.dark ? null : color,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(copy),
        ])),
      ]));
}
