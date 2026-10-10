import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/cloud_backend.dart';
import 'components/app_theme.dart';
import 'screen/splash_page.dart';
import 'state/app_state.dart';
import 'screen/login_screen.dart';
import 'components/botanical_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  CloudBackend? backend;
  String? error;
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    backend = FirebaseBackend();
  } catch (failure) {
    debugPrint('Firebase startup failed: $failure');
    error =
        'Account services could not connect. Check your connection and restart Plantify.';
  }
  final state = await AppState.load(backend: backend, connectionError: error);
  runApp(MyApp(state: state));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.state});
  final AppState? state;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _state = widget.state ?? AppState();
  final _navigator = GlobalKey<NavigatorState>();
  late bool _signedIn;
  @override
  void initState() {
    super.initState();
    _signedIn = _state.activeSession;
    _state.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    final expired = _signedIn && !_state.activeSession;
    _signedIn = _state.activeSession;
    if (expired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _navigator.currentState?.pushAndRemoveUntil(
            botanicalRoute<void>(const LoginScreen()), (_) => false);
      });
    }
  }

  @override
  void dispose() {
    _state.removeListener(_sessionChanged);
    if (widget.state == null) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScope(
      state: _state,
      child: AnimatedBuilder(
          animation: _state,
          builder: (_, __) => MaterialApp(
                title: 'Plantify',
                navigatorKey: _navigator,
                debugShowCheckedModeBanner: false,
                theme: Botanical.theme(),
                darkTheme: Botanical.theme(dark: true),
                themeMode: _state.darkMode ? ThemeMode.dark : ThemeMode.light,
                themeAnimationDuration: const Duration(milliseconds: 300),
                home: const SplashPage(),
              )));
}
