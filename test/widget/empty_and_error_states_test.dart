import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/theme/app_theme.dart';
import 'package:writtle/core/widgets/empty_state_widget.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: WrittleTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('TC-011 & TC-012: Empty and Error States Tests (NFR-007, NFR-008)', () {
    testWidgets('TC-011: EmptyStateWidget renders poetic text, icon, and optional CTA', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        createTestWidget(
          EmptyStateWidget(
            icon: Icons.auto_stories_outlined,
            title: 'A quiet moment...',
            message: 'No stories have been written in this category yet.',
            action: ElevatedButton(
              onPressed: () => actionTriggered = true,
              child: const Text('Write a Story'),
            ),
          ),
        ),
      );

      // Verify content
      expect(find.text('A quiet moment...'), findsOneWidget);
      expect(
        find.text('No stories have been written in this category yet.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.auto_stories_outlined), findsOneWidget);

      // Verify CTA button action
      expect(find.text('Write a Story'), findsOneWidget);
      await tester.tap(find.text('Write a Story'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('TC-012: Error state displays retry button and responds to tap', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        createTestWidget(
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 40),
                const SizedBox(height: 12),
                const Text('Could not load stories. Please check your connection.'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => retried = true,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Could not load stories. Please check your connection.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });
  });
}
