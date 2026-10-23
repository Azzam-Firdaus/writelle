import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/main.dart';

void main() {
  testWidgets('MainShellScreen bottom navigation tab transitions', (tester) async {
    await tester.pumpWidget(const WrittleApp());
    await tester.pump();

    // Verify initial screen is Stories tab
    expect(find.text('Writtle'), findsOneWidget);

    // Tap Saved tab
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    // Verify Saved tab view is shown
    expect(find.text('Saved Stories'), findsOneWidget);

    // Tap Profile tab
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verify Profile tab view is shown
    expect(find.text('My Profile'), findsOneWidget);

    // Tap Stories tab to return to Home
    await tester.tap(find.byIcon(Icons.auto_stories_outlined));
    await tester.pumpAndSettle();

    // Verify Home tab is active again
    expect(find.text('Writtle'), findsOneWidget);
  });
}
