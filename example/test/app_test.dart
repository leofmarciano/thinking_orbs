import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinking_orbs/thinking_orbs.dart';
import 'package:thinking_orbs_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const OrbsPlaygroundApp());
    await tester.pump();
  }

  testWidgets('uses one grid column on compact screens', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    final working =
        tester.getRect(find.byKey(const ValueKey('orb-card-working')));
    final searching =
        tester.getRect(find.byKey(const ValueKey('orb-card-searching')));

    expect(searching.top, greaterThan(working.top));
    expect(searching.left, working.left);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses three grid columns on wide screens', (tester) async {
    await pumpAtSize(tester, const Size(1200, 900));

    final working =
        tester.getRect(find.byKey(const ValueKey('orb-card-working')));
    final searching =
        tester.getRect(find.byKey(const ValueKey('orb-card-searching')));
    final solving =
        tester.getRect(find.byKey(const ValueKey('orb-card-solving')));
    final listening =
        tester.getRect(find.byKey(const ValueKey('orb-card-listening')));

    expect(searching.top, working.top);
    expect(solving.top, working.top);
    expect(listening.top, greaterThan(working.top));
    expect(working.left, lessThan(searching.left));
    expect(searching.left, lessThan(solving.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('play, pause, theme and color controls update the demo', (
    tester,
  ) async {
    await pumpAtSize(tester, const Size(1200, 900));

    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.byTooltip('Light mode'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.tap(find.byTooltip('Light mode'));
    await tester.pump();
    expect(find.byTooltip('Dark mode'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('color-emerald')));
    await tester.pumpAndSettle();
    final orb = tester.widget<ThinkingOrb>(find.byType(ThinkingOrb).first);
    expect(orb.color, const Color(0xFF34D399));
    expect(tester.takeException(), isNull);
  });
}
