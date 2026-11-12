import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/screens/admin/admin_cms_screen.dart';

void main() {
  testWidgets('AdminCmsScreen renders header, 6 tabs, and dashboard metrics', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminCmsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar Title
    expect(find.text("Curator's Chamber"), findsOneWidget);

    // Verify All 6 Tabs
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.text('Moderation'), findsOneWidget);
    expect(find.text('Scrolls'), findsOneWidget);
    expect(find.text('Realms'), findsOneWidget);
    expect(find.text('Scribes'), findsOneWidget);
    expect(find.text('Audit Logs'), findsOneWidget);

    // Verify Metric Titles in Pulse Tab
    expect(find.text('Sanctuary Metrics'), findsOneWidget);
    expect(find.text('Total Scrolls'), findsOneWidget);
    expect(find.text('Veiled Scrolls'), findsOneWidget);
    expect(find.text('Flagged Reports'), findsOneWidget);
    expect(find.text('Trash / Retained'), findsOneWidget);
    expect(find.text('Curator Operations'), findsOneWidget);
  });

  testWidgets('AdminCmsScreen switches between tabs smoothly', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminCmsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on 'Realms' Tab
    await tester.tap(find.text('Realms'));
    await tester.pumpAndSettle();

    // Should find 'Forge Realm' button
    expect(find.text('Forge Realm'), findsOneWidget);

    // Tap on 'Scrolls' Tab
    await tester.tap(find.text('Scrolls'));
    await tester.pumpAndSettle();

    expect(find.text('All Scrolls'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);

    // Tap on 'Moderation' Tab
    await tester.tap(find.text('Moderation'));
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Reviewed'), findsOneWidget);

    // Tap on 'Audit Logs' Tab
    await tester.tap(find.text('Audit Logs'));
    await tester.pumpAndSettle();

    expect(find.text('All Actions'), findsOneWidget);
  });

  testWidgets('AdminCmsScreen renders clean AppBar without notification bell and clean tabs without badges', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AdminCmsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Notification Bell icon is NOT present in AppBar
    final bellFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          (widget.icon == Icons.notifications_active_outlined ||
              widget.icon == Icons.notifications_none_outlined),
    );
    expect(bellFinder, findsNothing);

    // Verify Refresh button is present
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
