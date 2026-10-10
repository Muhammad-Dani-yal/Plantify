import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/screen/plant_chat.dart';
import 'package:myapp/services/plant_guide.dart';
import 'package:myapp/state/app_state.dart';
import 'fake_backend.dart';

class TestGuide implements PlantGuide {
  final calls = <List<GuideMessage>>[];
  bool fail = false;
  Completer<String>? pending;
  String? context;
  @override
  Future<String> answer(List<GuideMessage> history, String plantContext) async {
    calls.add(history.toList());
    context = plantContext;
    if (fail) throw StateError('Offline');
    if (pending != null) return await pending!.future;
    return 'Check the soil moisture first.';
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true));
  tearDown(
      () => binding.platformDispatcher.clearAccessibilityFeaturesTestValue());
  Future<AppState> mount(WidgetTester tester, TestGuide guide) async {
    final state = AppState(backend: FakeBackend(signedIn: true));
    await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(
            home:
                PlantChatScreen(guide: guide, plantContext: 'Citrus limon'))));
    await tester.pumpAndSettle();
    return state;
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byTooltip('Send question'));
    await tester.pumpAndSettle();
  }

  testWidgets('Passes botanical context and completed conversation to AI',
      (tester) async {
    final guide = TestGuide();
    final state = await mount(tester, guide);
    await send(tester, 'Mera lemon plant peela hai');
    expect(guide.context, 'Citrus limon');
    await send(tester, 'Kitna paani dun?');
    expect(guide.calls.last.map((m) => m.fromUser), [true, false, true]);
    expect(guide.calls.last.first.text, 'Mera lemon plant peela hai');
    state.dispose();
  });
  testWidgets('Failure preserves question; retry does not duplicate the turn',
      (tester) async {
    final guide = TestGuide()..fail = true;
    final state = await mount(tester, guide);
    await send(tester, 'How do I plant a mango?');
    expect(find.text('Retry question'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'How do I plant a mango?');
    guide.fail = false;
    await tester.tap(find.text('Retry question'));
    await tester.pumpAndSettle();
    expect(guide.calls.last.length, 1);
    expect(find.text('Check the soil moisture first.'), findsOneWidget);
    state.dispose();
  });
  testWidgets('Reset ignores a late AI response', (tester) async {
    final guide = TestGuide()..pending = Completer<String>();
    final state = await mount(tester, guide);
    await tester.enterText(find.byType(TextField), 'Help me');
    await tester.tap(find.byTooltip('Send question'));
    await tester.pump();
    await tester.tap(find.byTooltip('New conversation'));
    await tester.pump();
    guide.pending!.complete('Old answer');
    await tester.pumpAndSettle();
    expect(find.text('Old answer'), findsNothing);
    expect(find.text('1 · Choose a plant'), findsOneWidget);
    state.dispose();
  });
}
