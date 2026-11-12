import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/writelle_logo.dart';
import 'package:writtle/main.dart';

void main() {
  testWidgets('MainShellScreen bottom navigation tab transitions', (tester) async {
    await tester.pumpWidget(const WritelleApp());
    await tester.pump();
    // Advance past splash screen into MainShellScreen
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify initial screen is Beranda tab with brand logo
    expect(find.byType(WritelleLogo), findsOneWidget);

    // Tap Keepsakes tab (guest prompts auth dialog)
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    // Verify Keepsakes prompts auth popup for guest
    expect(find.text('Keepsakes Sanctuary'), findsOneWidget);
    expect(find.text('Sign In / Join'), findsOneWidget);

    // Dismiss prompt
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Tap Profile tab
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    // Verify Profile tab directly displays login form for guest
    expect(find.text('Sign In to Sanctuary'), findsOneWidget);

    // Tap Beranda tab to return to Home
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    // Verify Home tab is active again with brand logo
    expect(find.byType(WritelleLogo), findsOneWidget);
  });
}
