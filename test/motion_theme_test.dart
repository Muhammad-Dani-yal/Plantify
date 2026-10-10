import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/components/app_theme.dart';
import 'package:myapp/components/motion_icon.dart';

void main() {
  testWidgets('Live icons animate and settle with reduced motion',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: MotionIcon(Icons.auto_awesome, live: true))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MotionIcon(Icons.auto_awesome, live: true))));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
  test('Dark surfaces are neutral charcoal with readable contrast', () {
    final colors = Botanical.theme(dark: true).colorScheme;
    expect((colors.surface.g - colors.surface.r).abs(), lessThan(.03));
    final contrast = (colors.onSurface.computeLuminance() + .05) /
        (colors.surface.computeLuminance() + .05);
    expect(contrast, greaterThan(7));
  });
}
