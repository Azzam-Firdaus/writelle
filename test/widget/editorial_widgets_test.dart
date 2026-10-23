import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/theme/app_theme.dart';
import 'package:writtle/core/widgets/anonymity_toggle.dart';
import 'package:writtle/core/widgets/category_chip.dart';
import 'package:writtle/core/widgets/editorial_button.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: WrittleTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Editorial UI Atom Widgets Tests', () {
    testWidgets('EditorialButton renders label and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestWidget(
          EditorialButton(
            label: 'Publish Story',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Publish Story'), findsOneWidget);
      await tester.tap(find.text('Publish Story'));
      expect(tapped, isTrue);
    });

    testWidgets('EditorialButton shows progress indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const EditorialButton(
            label: 'Publishing',
            isLoading: true,
            onPressed: null,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CategoryChip renders and handles tap', (tester) async {
      bool chipTapped = false;
      await tester.pumpWidget(
        createTestWidget(
          CategoryChip(
            label: 'Reflections',
            isSelected: false,
            onTap: () => chipTapped = true,
          ),
        ),
      );

      expect(find.text('Reflections'), findsOneWidget);
      await tester.tap(find.text('Reflections'));
      expect(chipTapped, isTrue);
    });

    testWidgets('AnonymityToggle displays correct text based on state', (tester) async {
      bool isAnon = true;

      await tester.pumpWidget(
        createTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AnonymityToggle(
                isAnonymous: isAnon,
                penName: 'UrbanMonk',
                onChanged: (val) {
                  setState(() => isAnon = val);
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Publishing Anonymously'), findsOneWidget);

      // Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('Publishing as UrbanMonk'), findsOneWidget);
    });
  });
}
