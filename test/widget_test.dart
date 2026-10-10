import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/main.dart';
import 'package:myapp/components/app_theme.dart';
import 'package:myapp/components/validators.dart';
import 'package:myapp/data/plants.dart';
import 'package:myapp/state/app_state.dart';
import 'package:myapp/screen/start_page.dart';
import 'package:myapp/screen/splash_page.dart';
import 'package:myapp/screen/login_screen.dart';
import 'package:myapp/screen/sign_up.dart';
import 'package:myapp/screen/forgot_password.dart';
import 'package:myapp/screen/home_page.dart';
import 'package:myapp/screen/search.dart';
import 'package:myapp/screen/profile.dart';
import 'package:myapp/screen/plant_match.dart';
import 'package:myapp/screen/plant_details.dart';
import 'fake_backend.dart';

Widget harness(Widget child, AppState state) => AppScope(
    state: state,
    child: MaterialApp(
        theme: Botanical.theme(),
        home: child is SearchScreen || child is ProfileScreen
            ? Scaffold(body: child)
            : child));
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true));
  tearDown(
      () => binding.platformDispatcher.clearAccessibilityFeaturesTestValue());
  test('Email and password validation reject malformed input', () {
    for (final email in [
      '',
      'user',
      'user@host',
      'a@b.com trailing',
      'a b@c.com'
    ]) {
      expect(validateEmail(email), isNotNull);
    }
    expect(validateEmail(' user@example.com '), isNull);
    expect(validatePassword('short'), isNotNull);
    expect(validatePassword('password123'), isNull);
  });
  test('100 unique plants have photos and complete care facts', () {
    expect(plants.length, 100);
    expect(plants.map((p) => p.id).toSet().length, 100);
    for (final p in plants) {
      expect(File(p.imagePath).existsSync(), isTrue, reason: p.name);
      expect(p.description, isNotEmpty);
      expect(p.soil, isNotEmpty);
      expect(p.waterDays, greaterThan(0));
      if (p.imagePath.startsWith('assets/catalogue/')) {
        expect(p.imageCredit, isNotEmpty);
        expect(p.imageSource, startsWith('https://'));
      }
    }
  });
  test('All bundled plant and welcome images decode after compression',
      () async {
    final paths = {
      ...plants.map((plant) => plant.imagePath),
      'assets/botanical/greenhouse-hero.webp',
    };
    for (final path in paths) {
      final codec =
          await ui.instantiateImageCodec(await File(path).readAsBytes());
      try {
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: path);
        expect(frame.image.height, greaterThan(0), reason: path);
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });
  test('Search combines care terms, botanical names and collections', () {
    expect(
        plants
            .where((p) =>
                const PlantFilter(light: 'Low light').matches(p, 'snake'))
            .single
            .id,
        'snake');
    expect(
        plants
            .where((p) => const PlantFilter(category: 'Herbs').matches(p, ''))
            .length,
        greaterThanOrEqualTo(8));
    expect(
        plants.where(
            (p) => const PlantFilter(water: 'Low').matches(p, 'monstera')),
        isEmpty);
    expect(
        plants.where((p) => const PlantFilter().matches(p, 'low light indoor')),
        isNotEmpty);
    expect(
        plants
            .where((p) => const PlantFilter().matches(p, 'Phalaenopsis'))
            .single
            .id,
        'moth-orchid');
  });
  testWidgets('Splash routes to welcome and cancels timer on disposal',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashPage), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(StartPage), findsOneWidget);
    await tester.pumpWidget(const MyApp(key: ValueKey('new')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Login validates then authenticates and opens home',
      (tester) async {
    final backend = FakeBackend();
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const LoginScreen(), state));
    await tapVisible(tester, find.text('Sign in'));
    expect(find.text('Email is required'), findsOneWidget);
    expect(backend.signInCalls, 0);
    await tester.enterText(
        find.byKey(const ValueKey('email-field')), 'user@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('password-field')), 'password123');
    await tapVisible(tester, find.text('Sign in'));
    expect(find.byType(HomePage), findsOneWidget);
    expect(state.activeSession, isTrue);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  testWidgets('Invalid credentials stay on login and show an error',
      (tester) async {
    final backend = FakeBackend();
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const LoginScreen(), state));
    await tester.enterText(
        find.byKey(const ValueKey('email-field')), 'user@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('password-field')), 'wrongpassword');
    await tapVisible(tester, find.text('Sign in'));
    expect(find.byType(HomePage), findsNothing);
    expect(find.text('The email or password is incorrect. Please try again.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  testWidgets('Missing backend never authenticates locally', (tester) async {
    final state = AppState();
    await tester.pumpWidget(harness(const LoginScreen(), state));
    await tester.enterText(
        find.byKey(const ValueKey('email-field')), 'user@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('password-field')), 'password123');
    await tapVisible(tester, find.text('Sign in'));
    expect(state.activeSession, isFalse);
    expect(find.byType(HomePage), findsNothing);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Signup creates account and obscures password', (tester) async {
    final backend = FakeBackend();
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const LoginScreen(), state));
    await tapVisible(tester, find.text('Create account'));
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(
        tester
            .widget<TextField>(find.descendant(
                of: find.byKey(const ValueKey('password-field')),
                matching: find.byType(TextField)))
            .obscureText,
        isTrue);
    await tester.enterText(find.byKey(const ValueKey('name-field')), 'Ayesha');
    await tester.enterText(
        find.byKey(const ValueKey('email-field')), 'a@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('password-field')), 'password123');
    await tapVisible(tester, find.text('Create account'));
    expect(find.byType(HomePage), findsOneWidget);
    expect(state.name, 'Ayesha');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  testWidgets('Reset succeeds only after the backend request succeeds',
      (tester) async {
    final backend = FakeBackend()..failReset = true;
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const ForgetScreen(), state));
    await tapVisible(tester, find.text('Send reset link'));
    expect(find.text('Email is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tapVisible(tester, find.text('Send reset link'));
    expect(
        find.text(
            'Could not connect. Check your internet connection and try again.'),
        findsOneWidget);
    backend.failReset = false;
    await tapVisible(tester, find.text('Send reset link'));
    expect(
        find.text(
            'If an account exists for this email, you will receive a password reset link. Check your inbox and spam folder.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  for (final screen in <Widget>[
    const StartPage(),
    const LoginScreen(),
    const SignUpScreen(),
    const ForgetScreen(),
    const HomePage(),
    const SearchScreen(),
    const ProfileScreen(),
    const PlantMatchScreen(),
    PlantDetailsScreen(plant: plants.first)
  ]) {
    testWidgets('${screen.runtimeType} fits narrow screen with keyboard',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final backend = FakeBackend(signedIn: true);
      final state = AppState(backend: backend);
      await tester.pumpWidget(harness(screen, state));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      await backend.dispose();
    });
  }
  test('Cloud data restores and signing out isolates the next account',
      () async {
    SharedPreferences.setMockInitialValues({});
    final backend = FakeBackend(signedIn: true);
    final state = await AppState.load(backend: backend);
    await Future<void>.delayed(Duration.zero);
    state.toggleFavorite('monstera');
    state.addPlant('snake');
    await Future<void>.delayed(Duration.zero);
    state.saveNotes('snake', 'Near the window');
    state.markWatered('snake');
    state.setDarkMode(true);
    await Future<void>.delayed(Duration.zero);
    await state.saved;
    final restored = AppState(backend: backend);
    await Future<void>.delayed(Duration.zero);
    expect(restored.favorites, contains('monstera'));
    expect(restored.garden['snake']!.notes, 'Near the window');
    expect(restored.garden['snake']!.lastWatered, isNotNull);
    expect(restored.darkMode, isTrue);
    await state.logout();
    await state.signIn('other@example.com', 'password123');
    await Future<void>.delayed(Duration.zero);
    expect(state.favorites, isEmpty);
    expect(state.garden, isEmpty);
    expect(state.comparison, isEmpty);
    state.dispose();
    restored.dispose();
    await backend.dispose();
  });
  test('Failed cloud writes can be retried without losing intent', () async {
    final backend = FakeBackend(signedIn: true);
    final state = AppState(backend: backend);
    await Future<void>.delayed(Duration.zero);
    backend.failWrites = true;
    state.toggleFavorite('monstera');
    await Future<void>.delayed(Duration.zero);
    expect(state.storageError, isNotNull);
    backend.failWrites = false;
    state.retrySync();
    await Future<void>.delayed(Duration.zero);
    expect(backend.documents['user']!['favorites'], contains('monstera'));
    expect(state.storageError, isNull);
    state.dispose();
    await backend.dispose();
  });
  test('Comparison is limited to three plants', () {
    final state = AppState();
    for (final p in plants.take(3)) {
      state.toggleCompare(p.id);
    }
    expect(() => state.toggleCompare(plants[3].id), throwsStateError);
    state.toggleCompare(plants.first.id);
    expect(state.comparison.length, 2);
    state.dispose();
  });
  testWidgets('Favourite to garden, watering and notes flow works',
      (tester) async {
    final backend = FakeBackend(signedIn: true);
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const HomePage(), state));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('favorite-monstera')), 200,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable))
            .first);
    await tapVisible(tester, find.byKey(const ValueKey('favorite-monstera')));
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Monstera'));
    await tapVisible(tester, find.text('Add to My Plants'));
    // Let the confirmation snackbar finish before tapping underlying garden actions.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Plants'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Record watering'));
    expect(state.garden['monstera']!.lastWatered, isNotNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Care notes'));
    await tester.enterText(find.byType(TextFormField), 'Bright corner');
    await tester.tap(find.text('Save notes'));
    await tester.pumpAndSettle();
    expect(find.text('Bright corner'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  testWidgets('Search query survives tab switching', (tester) async {
    final backend = FakeBackend(signedIn: true);
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const HomePage(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('plant-search')), 'orchid');
    await tester.pumpAndSettle();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plant-search')))
            .controller!
            .text,
        'orchid');
    tester.view.physicalSize = const Size(800, 600);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('plant-search')))
            .controller!
            .text,
        'orchid');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
  testWidgets('Welcome slideshow advances and can be paused', (tester) async {
    binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    final state = AppState();
    await tester.pumpWidget(harness(const StartPage(), state));
    await tester.pumpAndSettle();
    expect(
        find.text('Your next green\nobsession starts here.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.text('Less guessing.\nMore growing.'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Pause slideshow'));
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('Less guessing.\nMore growing.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
  testWidgets('Desktop discovery, search and profile fit', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final backend = FakeBackend(signedIn: true);
    final state = AppState(backend: backend);
    await tester.pumpWidget(harness(const HomePage(), state));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    await backend.dispose();
  });
}
