import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/writelle_logo.dart';
import 'package:writtle/main.dart';

void main() {
  testWidgets('WritelleApp smoke test loads brand title, navigation, and write action', (tester) async {
    await tester.pumpWidget(const WritelleApp());
    await tester.pump();
    // Advance time past the splash timer and page transition
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify brand logo in app bar
    expect(find.byType(WritelleLogo), findsOneWidget);

    // Verify Write action is visible
    expect(find.text('Pen'), findsOneWidget);

    // Verify bottom navigation bar tabs
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Keepsakes'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
